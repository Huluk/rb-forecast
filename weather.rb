#!/usr/bin/env ruby

require 'optparse'

require_relative 'geolocation'
require_relative 'forecast_io'

DEFAULT_OPTIONS = {
  language: 'en',
  units: 'auto',
  storm_warn_distance: 0,
  save: false,
  format_file: File.join(Forecast.data_dir, 'format.txt')
}
CONFIG_FILE = File.join(Forecast.data_dir, 'config.yml')

if File.exist? CONFIG_FILE
  options = YAML.load(File.read(CONFIG_FILE))
else
  $stderr.puts "warning: missing config file at #{CONFIG_FILE}"
end

options = Hashie::Mash.new(DEFAULT_OPTIONS.merge options)
 
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on('-k', '--key API-KEY', 'Foreast.io API key') do |key|
    options.api_key = key
  end

  opts.on('-l', '--loc PLACE', 'name of a location') do |place|
    options.location = place
  end

  opts.on('-e', '--long LONG', 'longitude as a decimal') do |lon|
    options.longitude = long.to_f
  end

  opts.on('-n', '--lat LAT', 'latitude as a decimal') do |lat|
    options.latitude = lat.to_f
  end

  opts.on('-f', '--format PATH', 'path to a format file') do |path|
    options.format_file = path
  end
  
  opts.on('-s', '--save', 'save location as default') do
    options.save = true
  end

  opts.on('-u', '--units',
          'select types of display units [us,si,ca,uk2,auto(default)]'
         ) do |units|
    options.units = units
  end

  opts.on('-h', '--help', 'displays this message') do
    puts opts
    exit
  end
end

optparse.parse!
options.location_file = File.join(Forecast.data_dir, 'location')
# check options
def validate(condition, message)
  if not condition
    $stderr.puts message
    exit(1)
  end
end
validate(ARGV.empty?, "unknown option `#{ARGV[0]}'!")
validate(File.exist?(Forecast.data_dir),
         "missing data directory `config'!")
validate(!options.longitude? || options.latitude?,
         "specified longitude but not latitude!")
validate(!options.latitude? || options.longitude?,
         "specified latitude but not longitude!")
validate(options.api_key?,
         "please specify a Forecast.io API key!")
validate(options.location? || (options.latitude? && options.longitude?) ||
         File.exist?(options.location_file),
         "please specify location or coordinates!")
validate(File.exist?(options.format_file),
         "could not finde format file `#{options.format_file}'!")

options.format = File.read(options.format_file)

# get coordinates by location
if options.location?
  # TODO what about multiple locations?
  coords = Geolocation.new(options).coordinates(options.location).first
  options.latitude = coords.latitude
  options.longitude = coords.longitude
elsif options.longitude? && options.latitude?
  coords = Coordinate.new(options.latitude, options.longitude)
else
  options.save = false
  options.location, *coords = YAML.load(File.read(options.location_file))
  options.latitude, options.longitude = coords
  coords = Coordinate.new(*coords)
end

if options.save
  File.write(options.location_file,
             YAML.dump([options.location!, coords.latitude, coords.longitude]))
end

forecast = ForecastIO.new(options).forecast(coords)
forecast.options = options

puts forecast.print(options.format)
