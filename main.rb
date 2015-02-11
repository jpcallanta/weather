#!/usr/bin/env ruby 

require './weather'

# MAIN
if ARGV.count == 0 
  puts "Missing zipcode argument"
  exit 
end

weather = Weather.new(ARGV[0])

weather.show_report