require_relative 'json_api'

class Coordinate
  attr_reader :longitude, :latitude

  def initialize(lat, long)
    @latitude = lat
    @longitude = long
  end
end

class Geolocation < JsonAPI
  URL = "https://maps.google.com/maps/api/geocode/json"

  attr_reader :language

  def initialize(options)
    @language = options.language
  end

  def coordinates(location)
    response = connect(URL, {language: @language, address: location})
    response = Hashie::Mash.new(JSON.parse(response))
    case response.status
    when "OK"
      return response.results.map { |result|
        coord = result.geometry.location
        Coordinate.new(coord.lat, coord.lng)
      }
    when "ZERO_RESULTS"
      raise(IOError, "Could not find the location `#{options.location}'!")
    else
      raise(IOError, "Unknown response in Geocode API call:\n#{result}")
    end
  end
end
