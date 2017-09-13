# frozen_string_literal: true

require 'csv'

module XMLParser
  class MyParser < Nokogiri::XML::SAX::Document
  attr_reader :csv

    def initialize(filename, definitions, step=100)
      case definitions.class.name
      when "Hash"
        @definitions = [definitions]
      when "Array"
        @definitions = definitions
      else
        raise "definition type not supported"
      end
      raise "minimum step is 100" if step < 100
      @filename = filename
      @row, @csv = [], []
      @counter = 0
      @start_time = Time.now
      @step = step
      @csv = [['LEI', 'LegalName', 'BusinessRegisterEntityID']]
      save_data
      @csv = []
      @mode = :all if @definitions.first[:mode] == "all"
      @mode = :debug #if @definitions.first[:mode] == "debug"
      super()
    end

    def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = [])
      @characters_bit = 0
      @context = name == 'LEIRecord' ? SecureRandom.uuid : @context
      #puts "#{@context}: #{@counter}: #{__method__}: #{name}" if condition
      @element_name = name
      attributes = attrs.first
      if attributes.nil? || attributes == ''
        @attributes = nil
      else
        @attributes = OpenStruct.new(attributes)
      end
    end

    def condition
      [8, 18].include? @counter
      #[:all, :debug].include?(@mode)
      #if @mode == :debug
    end

    def characters(string)
      value = string.strip
      #puts "#{@context}: #{@counter}: #{__method__}: #{@element_name} > #{@attributes&.localname} > #{@attributes&.value}: #{value}/#{value.size}" if condition
      current_field_hash = {}
      current_field_hash = {element: @element_name, attribute: @attributes&.localname, attr_value: @attributes&.value}
      if match(@definitions, current_field_hash)
        #puts "#{@context}: #{@counter}: #{__method__}: __matched__: #{@element_name}, #{string}" if condition
        if @characters_bit == 0
          @row << value
        else
          @row[-1] = @row[-1].to_s + value.to_s
        end
      end
      @characters_bit = 1
    end

    def end_element_namespace(name, prefix = nil, uri = nil)
      # Pokus o tvorbu radku pokud se parsuje vice nez jeden element
      if name == 'LEIRecord'
        @counter += 1
        @csv << @row
        @row = []
        # Ulozeni davky do CSV
        if @counter % @step == 0
          elapsed_time = time_diff(@start_time, Time.now)
          save_data
          @csv = []
          recs_per_sec = (@step / elapsed_time).round(0)
          puts "#{@counter} records, took #{elapsed_time} sec, #{recs_per_sec} rec/sec"
          @start_time = Time.now
        end
      end
    end

    def end_document
      save_data
    end

    private
    def time_diff(start, finish)
      (finish - start).round(1)
    end

    def match(definitions, current_field_hash)
      definitions.any? do |definition|
        definition.keys.all? do |key|
          current_field_hash.include?(key)
          current_field_hash[key] == definition[key]
        end
      end
    end

    def save_data
      CSV.open("public/#{@filename}.csv", 'ab', col_sep: ';') do |row|
        @csv.each do |item|
          row << item
        end
      end
    end

  end
end
