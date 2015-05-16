#!/usr/bin/env ruby

require 'rubygems'
require 'faster_csv'
require 'lib/parser.rb'

def run(command)
  puts command
  system(command)
end

run("mkdir -p csv")

Dir.glob("data/*").each do |file|
  if file.match(/\.fit$/i)
    csv_filename = File.basename(file).sub(/\.fit$/i, '.csv').downcase
    csv = File.join("csv", csv_filename)
    if !File.exists?(csv)
      run("java -jar FitCSVTool.jar -b %s %s" % [file, csv])
    end
  end
end

Dir.glob("csv/*_data.csv").each do |file|
  data = Parser.parse(file)
  break
end
