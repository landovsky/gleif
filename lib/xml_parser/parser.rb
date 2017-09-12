# frozen_string_literal: true

require 'benchmark'

module XMLParser
  class Parser
    def initialize(file, element)
      @file = file
      @element = element
      raise 'Element definition must be a Hash {element: string, attribute: string, attr_value: string}' unless @element.class.name == 'Hash'
      raise 'File does not exist. Put it in tmp/' unless File.exist?("tmp/#{@file}")
    end

    def dom
      DomParser.new(@file, @element)
    end

    def sax
      parser = Nokogiri::XML::SAX::Parser.new(SAXParser.new(@element))
      parser.parse(File.open("tmp/#{@file}"))
      parser.document
    end
  end
end
