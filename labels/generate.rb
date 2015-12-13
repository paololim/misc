#!/usr/bin/env ruby

require "prawn"
require "prawn/measurement_extensions"
require 'csv'
Prawn::Font::AFM.hide_m17n_warning = true

class Address

  attr_reader :lines, :zip

  def initialize(data)
    @zip = to_zip(data[:zipcode])
    csz = join([join([data[:city], data[:state]]), @zip], ", ")

    @lines = [
      join([data[:firstname], data[:lastname]]),
      join([data[:address1]]),
      join([data[:address2]]),
      csz
    ].select { |el| !el.to_s.empty? }
  end

  def to_zip(value)
    v = value.to_s.strip
    if v.empty?
      nil
    else
      while v.length < 5
        v = "0" + v
      end
      v
    end
  end
  
  def join(els, joiner = " ")
    els.map(&:to_s).map(&:strip).select { |el| !el.empty? }.join(joiner)
  end

end

def each_row(path)
  headers = nil
  CSV.foreach(path) do |row|
    if headers.nil?
      headers = row.select { |el|
        !el.to_s.strip.empty?
      }.map { |el|
        el.downcase.gsub(/\s+/, '').strip.to_sym
      }
    else
      map = {}
      headers.each_with_index do |name, i|
        value = row[i].to_s.strip
        if !value.empty?
          map[name] = value
        end
      end

      address = Address.new(map)
      if address.lines.size < 2
        puts "** WARNING ** Invalid address: " + map.inspect
      elsif address.zip.nil?
        puts "** WARNING ** Missing zip: " + map.inspect
      else
        yield address
        #break
      end
    end
  end
end

first = true
Prawn::Document.generate("hello.pdf") do
  top_margin = 0.2
  font_size = 16
  #stroke_axis

  each_row("domestic.csv") do |address|
    if !first
      start_new_page
    end
    first = false

    #address_indent = 25
    #text "Michael and Lisa Bryzek", :indent_paragraphs => address_indent
    #text "334 Hamilton Ave", :indent_paragraphs => address_indent
    #text "Glen Rock, NJ 07452", :indent_paragraphs => address_indent

    move_down 50.mm
    label_indent = 225
    address.lines.each do |line|
      text line, :indent_paragraphs => label_indent
    end
  end

end
