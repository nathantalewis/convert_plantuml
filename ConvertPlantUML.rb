#!/usr/bin/env ruby
require 'optparse'
#require 'optparse/uri'
require 'ostruct'
require 'open-uri'
require_relative 'vendor/plantuml-encode64'

class ConvertPlantUML
  attr_reader :options

  def initialize()
    @options = OpenStruct.new
    @options.verbose = false
    @options.serverURI = URI.parse("http://www.plantuml.com/plantuml/")
    @options.type = 'png'
  end

  #TODO: Add support for HTTP headers for input, output and server requests
  #
  # Return a structure describing the options.
  #
  def parse(args)
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__} [options]"

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-i", "--input [URI]", #URI,
              "The source uri for your PlantUML diagram. If ommitted, STDIN will be used.") do |inputURI|
        @options.inputURI = inputURI
      end
      
      opts.on("-o", "--output [FILENAME]", #URI,
              "The destination file name for your rendered PlantUML diagram. If ommitted, STDOUT will be used.") do |outputFilename|
        @options.outputFilename = outputFilename
      end

      opts.on("-s", "--server [URI]", #URI,
              "The server uri for rendering your PlantUML diagram. The default is http://www.plantuml.com/plantuml/.") do |serverURI|
        @options.serverURI = if serverURI.end_with? '/' then serverURI + '/' else serverURI end
      end

      opts.on("-t", "--type [TYPE]", ['png', 'svg', 'txt'],
              "The output type (png, svg, txt). The default is png.") do |t|
        if t
          @options.type = t
        else
          puts "ERROR: Unknown type."
          exit 1
        end
      end

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        @options.verbose = v
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      # TODO: Add version
      #opts.on_tail("-V", "--version", "Show version") do
      #  puts ::Version.join('.')
      #  exit
      #end
    end

    opt_parser.parse!(args)
    self
  end

  #TODO: Add ensures to make sure the files are closed
  def convert(type: @options.type, server: @options.serverURI, input: @options.inputURI, output: @options.outputFilename)
    $stderr.puts "Reading input file... #{input}" if @options.verbose
    inputFile = if input then open(input) else $stdin end
    inputString = inputFile.read
    inputFile.close

    encodedURI = URI.join(server, "#{type}/", PlantUmlEncode64.new(inputString).encode())
    $stderr.puts "Retrieving data from #{encodedURI}" if @options.verbose
    response = open(encodedURI)
    
    $stderr.puts "Writing output file... #{output}" if @options.verbose
    outputFile = if output then open(output, 'w') else $stdout end
    outputFile.print response.read
    outputFile.close
  end
end

if __FILE__ == $0
  converter = ConvertPlantUML.new.parse(ARGV)
  converter.convert
end

