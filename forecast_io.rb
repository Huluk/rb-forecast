require_relative 'json_api'
require_relative 'forecast'

# currently not using forecast_io gem:
# gem does not zip data (more data sent, cannot use hourly 7 day forecasts)
# and all web handling is the same for geocoding api anyway
class ForecastIO < JsonAPI
  URL = "https://api.forecast.io/forecast/%s/%f,%f%s"

  attr_reader :params

  def initialize(options)
    @api_key = options.api_key
    @params = {
      units: options.units,
      lang: options.language,
      exclude: 'minutely',
    }
  end

  def forecast(coordinate, time=nil)
    time = time.nil? ? '' : ",#{time.to_i}"
    url = URL % [@api_key, coordinate.latitude, coordinate.longitude, time]
    response = connect(url, params)
    return Forecast.new(Hashie::Mash.new(JSON.parse(response)))
  end
end
