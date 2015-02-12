#!/usr/bin/env ruby

require 'HTTParty'
require 'date'

class Weather
  def initialize(zipcode)
    @weather_gov_url = 'http://graphical.weather.gov/xml/SOAP_server/ndfdXMLclient.php?whichClient='
    @location = Hash.new
    @zip = zipcode
    @date_begin = Date.today.to_s
    @date_end = (Date.today + 7).to_s
    @snow_time = []
    @snow_data = []
    @snow_hashed = Hash.new
    @snow_totals = 0.0
    @max_temp_time = []
    @max_temp_data = []
    @max_temp_hashed = Hash.new
    @min_temp_time = []
    @min_temp_data = []
    @min_temp_hashed = Hash.new
    @weather = Hash.new
    @max_temp_avg = 0.0
    @min_temp_avg = 0.0
  end

  def get_loc_by_zip(zip)
    request = "#{@weather_gov_url}LatLonListZipCode&listZipCodeList=#{zip}"

    resp = HTTParty.get(request)
    resp_hash = resp.parsed_response['dwml'].to_h
    location = resp_hash['latLonList'].split(',')
    @location[:lat] = location[0]
    @location[:long] = location[1]
  end

  def get_weekly_snow
    request = "#{@weather_gov_url}NDFDgenMultiZipCode&zipCodeList=#{@zip}&product=time-series&begin=#{@date_begin}&end=#{@date_end}&Unit=e&snow=snow&Submit=Submit"
    
    begin
      resp = HTTParty.get(request)
    rescue Exception => e
      puts e.message
    end
    
    @snow_hashed = resp.parsed_response['dwml'].to_h
    @snow_data = @snow_hashed['data']['parameters']['precipitation']['value']
    @snow_time = @snow_hashed['data']['time_layout']['start_valid_time']
  end

  def get_weekly_max_temp
    request = "#{@weather_gov_url}NDFDgenMultiZipCode&zipCodeList=#{@zip}&product=time-series&begin=#{@date_begin}&end=#{@date_end}&Unit=e&maxt=maxt&Submit=Submit"
    
    begin
      resp = HTTParty.get(request)
    rescue Exception => e
      puts e.message
    end
    
    @max_temp_hashed = resp.parsed_response['dwml'].to_h
    @max_temp_data = @max_temp_hashed['data']['parameters']['temperature']['value']
    @max_temp_time = @max_temp_hashed['data']['time_layout']['start_valid_time']
  end

  def get_weekly_min_temp
    request = "#{@weather_gov_url}NDFDgenMultiZipCode&zipCodeList=#{@zip}&product=time-series&begin=#{@date_begin}&end=#{@date_end}&Unit=e&mint=mint&Submit=Submit"
    
    begin
      resp = HTTParty.get(request)
    rescue Exception => e
      puts e.message
    end
    
    @min_temp_hashed = resp.parsed_response['dwml'].to_h
    @min_temp_data = @min_temp_hashed['data']['parameters']['temperature']['value']
    # @min_temp_time = @min_temp_hashed['data']['time_layout']['start_valid_time']
  end

  def total_snow
    @snow_data.each do |snow|
      @snow_totals += snow.to_f
    end
  end

  def avg_max_temp
    max_temp_avg = 0.0

    @max_temp_data.each do |max|
      max_temp_avg += max.to_f
    end

    @max_temp_avg = max_temp_avg / @max_temp_data.count
  end

  def avg_min_temp
    min_temp_avg = 0.0

    @min_temp_data.each do |min|
      min_temp_avg += min.to_f
    end

    @min_temp_avg = min_temp_avg / @min_temp_data.count
  end

  def show_report
    get_weekly_snow
    total_snow
    get_weekly_max_temp
    get_weekly_min_temp
    avg_max_temp
    avg_min_temp

    if @snow_hashed.empty? || @snow_data.empty? || @snow_time.empty?
      puts "No data... terminating"
      exit
    end

    puts "[Data from weather.gov]"
    puts ""
    puts "Snow accumulation for #{@zip}:"
    puts "---------------------------"

    count = 0
    
    @snow_time.each do |t|
      t.gsub!('T', ' ')
      t.gsub!('-05:00','')

      day = Date.parse(t).strftime("%A")

      puts "#{t} - #{day}, #{@snow_data[count]} inches"

      count = count + 1
    end

    puts "Total snow for #{@zip}: #{format('%.2f', @snow_totals)} inches"
    puts ""
    puts "Temperature for #{@zip}:"
    puts "--------------------"

    count = 0

    @max_temp_time.each do |t|
      t.gsub!(/T.*/,'')

      day = Date.parse(t).strftime("%A")

      puts "#{t} - #{day}, Hi:#{@max_temp_data[count]}F Low:#{@min_temp_data[count]}F"

      count = count + 1
    end
    puts "Avg Max temp: #{format('%.2f', @max_temp_avg)}"
    puts "Avg Min temp: #{format('%.2f', @min_temp_avg)}"
    puts ""
  end
end