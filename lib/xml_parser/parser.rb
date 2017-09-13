# frozen_string_literal: true

require 'benchmark'

module XMLParser
  class Parser
    def initialize(file, element, steps = 100)
      @file = file
      @element = element
      @steps = steps
      #raise 'Element definition must be a Hash {element: string, attribute: string, attr_value: string}' unless @element.class.name == 'Hash'
      raise 'File does not exist. Put it in tmp/' unless File.exist?("tmp/#{@file}")
    end

    def dom
      DomParser.new(@file, @element)
    end

    def sax
      parser = Nokogiri::XML::SAX::Parser.new(MyParser.new(@file, @element, @steps))
      parser.parse(File.open("tmp/#{@file}"))
      parser.document
    end
  end
end
