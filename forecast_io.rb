require 'time'

require_relative 'json_api'
require_relative 'forecast'

# currently not using forecast_io gem:
# gem does not zip data (more data sent, cannot use hourly 7 day forecasts)
# and all web handling is the same for geocoding api anyway
class ForecastIO < JsonAPI
  URL = "https://api.forecast.io/forecast/%s/%f,%f%s"
  HOUR = 3600

  attr_reader :params

  def initialize(options)
    @api_key = options.api_key
    @params = {
      units: options.units,
      lang: options.language
    }
    @params[:exclude] = 'minutely' unless options.minutely
    @params[:extend] = 'hourly' if options.hourly
  end

  def forecast(coordinate, time=nil)
    time = get_time_attribute(time)
    url = URL % [@api_key, coordinate.latitude, coordinate.longitude, time]
    response = connect(url, params)
    return Forecast.new(Hashie::Mash.new(JSON.parse(response)))
  end

  private

  def get_time_attribute(time)
    # Time.parse ignores additional 12:00 if time is already specified
    return time.nil? ? '' : ",#{Time.parse(time + " 12:00").to_i}"
  end
end
