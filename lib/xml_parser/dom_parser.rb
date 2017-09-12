# frozen_string_literal: true

require 'open-uri'
require 'zip'
require 'csv'

module XMLParser
  class DomParser
    attr_reader :data, :doc, :element

    def initialize(file, element = nil, step = nil)
      @file = file
      default_element = [ { element: 'lei|LEI'}, { element: 'lei|LegalName'}, { element: 'lei|BusinessRegisterEntityID'} ]
      @element = element.nil? ? default_element : element
      default_step = 10000
      @step = step.nil? ? default_step : step
      @query = search_query unless @element.class.name == 'Array'
      @data = []
      @counter = 0
      dom_parser
    end

    def search_query(element)
      element_name = element[:element]
      attribute = element[:attribute]
      attr_value = element[:attr_value]
      if attribute || attr_value
        raise "Both 'attribute' and 'attribute value' must be defined." unless attribute && attr_value
      end
      attribute_query = "[#{attribute}='#{attr_value}']" if attribute
      element_name.to_s + attribute_query.to_s
    end

    def dom_parser
      row = []
      start = Time.now
      @doc = Nokogiri::XML(File.open("tmp/#{@file}"))
      @records = @doc.xpath('//lei:LEIRecord', 'lei' => 'http://www.leiroc.org/data/schema/leidata/2014')
      total = @records.count
      @records.each do |record|
        @element.each do |element|
          row << record.css(search_query(element)).text.strip
        end
        @data << row
        @counter += 1
        row = []

        next unless @counter % @step == 0 || @counter == total

        CSV.open("public/#{@file}.csv", 'a', col_sep: ';') do |row|
          @data.each do |rec|
            row << rec
          end
        end
        @data = []

        #csv_start = Time.now
        # csv_elapsed = time_diff(csv_start, Time.now)
        # elapsed = time_diff(start, Time.now)
        # recs_per_sec = (@step / elapsed).round(0)
        # puts "#{@counter} records, took #{elapsed} sec, #{recs_per_sec} rec/sec. Writing took #{csv_elapsed} sec."
        # start = Time.now
      end

    end

    private

    def time_diff(start, finish)
      (finish - start).round(1)
    end

  end
end
