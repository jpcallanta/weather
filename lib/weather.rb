#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'

class Weather
  def initialize(zipcode)
    @zipcode = zipcode
    @min_max_forecast = Hash.new
    @xml_forecast = "http://graphical.weather.gov/xml/sample_products/browser_interface/ndfdBrowserClientByDay.php?zipCodeList=#{@zipcode}&format=12+hourly&numDays=10&Unit=e&snow=snow"

    begin
      @doc = Nokogiri::HTML(open(@xml_forecast))
    rescue Exception => e
      puts e.message
      exit 1
    end

    @min_max_layout_key = get_min_max_layout_key
    @time_line =
      @doc.xpath("//time-layout[layout-key='#{@min_max_layout_key}']").search('start-valid-time')
  end

  def get_min_max_layout_key
    return @doc.xpath('//time-layout/layout-key')[0].text
  end

  def get_min_max_temps
    max_temps = @doc.xpath("//temperature[@time-layout='#{@min_max_layout_key}']").search('value')
    min_temps = @doc.xpath("//temperature[@time-layout='#{@min_max_layout_key}']").search('value')
    count = 0

    @time_line.each do |tl|
      @min_max_forecast[tl.attribute('period-name')] = {
        max: max_temps[count].text,
        min: min_temps[count].text
      }

      count += 1
    end

    return @min_max_forecast
  end

  def show_min_max_temps
    self.get_min_max_temps()

    puts '-------------------------------------------------------'
    puts "Temps, next #{@min_max_forecast.count} days for #{@zipcode}"
    puts '-------------------------------------------------------'

    @min_max_forecast.each do |k, v|
      if v[:min] == ''
        puts "#{k} - Max:#{v[:max]}F Min:N/A"
      else
        puts "#{k} - Max:#{v[:max]}F Min:#{v[:min]}F"
      end
    end

puts ''
  end
end