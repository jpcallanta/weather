require 'open-uri'
require 'nokogiri'
require 'colorize'

class Weather
  def initialize(zipcode)
    @zipcode = zipcode
    @min_max_forecast = Hash.new
    @forecast = Hash.new
    @xml_forecast = "http://graphical.weather.gov/xml/sample_products/browser_interface/ndfdBrowserClientByDay.php?zipCodeList=#{@zipcode}&format=12+hourly&numDays=10&Unit=e&snow=snow"

    begin
      @doc = Nokogiri::HTML(open(@xml_forecast))
    rescue Exception => e
      puts e.message
      exit 1
    end

    @max_layout_key = get_max_layout_key
    @min_layout_key = get_min_layout_key
    @forecast_key = get_forecast_key
    @time_line =
      @doc.xpath("//time-layout[layout-key='#{@max_layout_key}']").search('start-valid-time')
    @time_line_forecast =
      @doc.xpath("//time-layout[layout-key='#{@forecast_key}']").search('start-valid-time')
  end

  def get_max_layout_key
    return @doc.xpath('//time-layout/layout-key')[0].text
  end

  def get_min_layout_key
    return @doc.xpath('//time-layout/layout-key')[1].text
  end

  def get_forecast_key
    return @doc.xpath('//time-layout/layout-key')[2].text
  end

  def get_min_max_temps
    max_temps = @doc.xpath("//temperature[@time-layout='#{@max_layout_key}']").search('value')
    min_temps = @doc.xpath("//temperature[@time-layout='#{@min_layout_key}']").search('value')
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

  def get_forecast
    conditions =
      @doc.xpath("//weather[@time-layout='#{@forecast_key}']").search('weather-conditions')
    precip_pct =
      @doc.xpath("//probability-of-precipitation[@time-layout='#{@forecast_key}']").search('value')
    count = 0

    @time_line_forecast.each do |t|
      @forecast[t.attribute('period-name')] = {
        condition: conditions[count].attribute('weather-summary'),
        precip: precip_pct[count].text,
      }

      count += 1
    end
  end

  def show_forecast
    self.get_forecast

    puts "Forecast, next #{(@forecast.count / 2).ceil} days for #{@zipcode}".colorize(:blue)

    @forecast.each do |k, v|
      if v[:condition].nil?
        puts "#{k} - N/A"
      else
        puts "#{k} - #{v[:condition]} Precipitation:#{v[:precip]}%"
      end
    end
  end

  def show_min_max_temps
    self.get_min_max_temps()

    puts "Temps, next #{@min_max_forecast.count} days for #{@zipcode}".colorize(:blue)

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