# frozen_string_literal: true

require 'open-uri'
require 'zip'

class DownloadManager
  attr_reader :filename, :url

  GLEIF_URL = 'https://www.gleif.org/en/lei-data/gleif-concatenated-file/download-the-concatenated-file'.freeze
  TEMP      = 'tmp/'.freeze
  PUBLIC    = 'public/'.freeze

  def perform
    # Check, that no other process is active and create lock for this process
    if JobStatus.active.any?
      MyLogger.logme('DownloadManager: perform begun while another process is active', level: 'warn')
      raise 'DownloadManager: perform begun while another process is active'
    end

    # Get remote filename
    if %w(development test).include? Rails.env
      @url      = 'http://localhost:3000/20170903-GLEIF-concatenated-file.zip'
      @filename = '20170903-GLEIF-concatenated-file.zip'
    else
      begin
        @url, @filename = DownloadManager.remote_filename
      rescue
      end
    end

    # Check if file exists and was correctly processed
    doc = Document.processed.find_by(name: @filename)
    if doc
      log("Document already successfully processed, doc: #{doc.id}")
      puts 'DownloadManager: Document already successfully processed'
      return
    end

    # Create document in DB and link with process
    @status = JobStatus.create(status: 'running')
    @document = Document.find_or_create_by(name: @filename, xml: @filename)
    @status.update(document_id: @document.id)

    # Fetch file
    if File.exist?("#{TEMP}#{@filename}")
      log('Aborting fetch, file already exists')
    else
      begin
        log('Fetching file')
        DownloadManager.fetch_file(@filename, @url)
        log('File fetched')
      rescue Exception => msg
        MyLogger.logme("DownloadManager: Fetching #{@filename} failed, err: #{msg}", level: 'fatal')
        File.delete("#{TEMP}/#{@filename}") unless File.size?("#{TEMP}/#{@filename}")
        @status.set('abort')
        raise msg
      end
    end

    # Unzip file and return unzipped filename
    begin
      log('Unzipping file')
      xml = DownloadManager.unzip(@filename)
      log("Unzipping done (#{xml})")
    rescue Exception => msg
      MyLogger.logme("DownloadManager: Uznipping failed, err: #{msg}", level: 'fatal')
      @status.set('abort')
      raise msg
    end

    # Converts xml to csv
    log('XML>CSV conversion started')
    elements = [{ element: 'LEI' }, { element: 'LegalName' }, { element: 'BusinessRegisterEntityID' }]
    begin
      XMLParser::Parser.new(xml, elements, 10000).sax
      if File.size?("#{PUBLIC}#{xml}.csv")
        log('XML>CSV conversion finished')
      else
        log('XML>CSV conversion FAILED, file empty')
        raise 'XML>CSV conversion FAILED, file empty.'
      end
    rescue Exception => msg
      @status.set('abort')
      MyLogger.logme("DownloadManager: XML>CSV conversion failed, err: #{msg}", level: 'fatal')
      raise msg
    end

    # Save file link to DB
    @document.update(csv: xml + '.csv')

    # Cleanup
    log("Cleanup FAILED. Files #{xml} #{@filename} not found") unless File.exist?("#{TEMP}#{xml}") && File.exist?("#{TEMP}#{@filename}")

    begin
      File.delete("#{TEMP}#{xml}")
      File.delete("#{TEMP}#{@filename}")
      log("Cleanup finished. Deleted #{xml}, #{@filename}")
    rescue Exception => msg
      log("Cleanup FAILED, error: #{msg}")
    end

    # Finish
    @status.update(status: 'complete')
    log("Finished successfully")
    puts 'DownloadManager: Finished successfully.'
  end

  def self.remote_filename
    doc = Nokogiri::HTML(open(GLEIF_URL))
    url = doc.css('a.leidata-download-btn').each_with_object([]) { |i, o| o << i[:href] }.grep(/concatenated-file.zip/).first
    filename = url.scan(/(.*)\/([0-9].*)/).last.last
    [url, filename]
  end

  def self.unzip(filename)
    Zip::File.open("#{TEMP}#{filename}") do |zip_file|
      MyLogger.logme("ZIP contains more than 1 file: #{zip_file}", level: 'fatal') if zip_file.count > 1
      return if zip_file.count > 1
      zip_file.each do |f|
        fpath = File.join(TEMP, f.name)
        if File.exist?(fpath)
        else
          zip_file.extract(f, fpath)
        end
        return f.name
      end
    end
  end


  def self.fetch_file(filename, url)
    new_file = "#{TEMP}#{filename}"
    open(new_file, 'wb') do |file|
      file << open(url).read
    end
  end

  private
  def log(message)
    Rails.logger.info("DownloadManager: #{message}. job_id: #{@status&.id}, remote_file: #{@filename}, document: #{@document&.id}")
  end
end
