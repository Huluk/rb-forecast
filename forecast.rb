require 'yaml'

require 'rubygems'
require 'hashie'
begin
  require 'colorize'
rescue LoadError
  class String
    def yellow() self; end
    def red() self; end
  end
end
require 'i18n' # internationalization
# find default locales here:
# https://github.com/svenfuchs/rails-i18n/tree/master/rails/locale

class Forecast
  DARKSKY_OFFLINE = 'darksky-unavailable'

  def self.data_dir
    @@data_dir
  end

  def self.setup
    @@data_dir = File.join(
      File.dirname(File.expand_path(__FILE__)), 'config')
    @@units = YAML.load(File.read(File.join(@@data_dir, 'units.yml')))
    @@units_regexp = Regexp.new(@@units['us'].keys.join('|'), Regexp::IGNORECASE)
    @@icons = YAML.load(File.read(File.join(@@data_dir, 'icons.yml')))
    @@icons.default = @@icons.delete 'default'
    @@moon = @@icons.delete 'moon'
    @@compass = %w(N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW)
    I18n.load_path += Dir[File.join(
      @@data_dir, 'locales', '*.{rb,yml}')]
    I18n.locale = I18n.default_locale
    validate_rubyversion
  end

  def self.validate_rubyversion
    # prior to ruby 2.3.0, sprintf does not support hash default values
    # and fails if there is no explicit value set. we need to explicitly
    # set all attributes to NA.
    @@set_flat_data_defaults = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3.0')
  end
  private_class_method :validate_rubyversion

  attr_reader :options
  def options=(opts)
    @options = opts
    I18n.locale = options.language if options.language?
    @flat_data[:location] = options.location
    @flat_data[:latitude] = options.latitude
    @flat_data[:longitude] = options.longitude
    @flat_data[:coordinates] =
      I18n.t('coordinates') % [options.latitude, options.longitude]
    @flat_data[:position] = @flat_data[:location] || @flat_data[:coordinates]
  end
  attr_reader :data
  attr_reader :units

  def initialize(forecast)
    @data = forecast
    @units = @@units[forecast.flags.units]
    make_flat_data(forecast)
    @flat_data.default = 'NA'
    @options = Hashie::Mash.new()
  end

  def print(format)
    puts format % @flat_data
  end

  def deg_to_compass(degree)
    @@compass[(degree/22.5).round % 16]
  end

  def moon(phase)
    @@moon[(phase/0.125).round % 8]
  end

  def bearing(degree)
    I18n.t "bearing.#{deg_to_compass(degree)}"
  end

  def unit(type)
    I18n.t "units.#{units[type]}"
  end

  def wind(obj)
    I18n.t('wind') % [obj.windSpeed, unit(:speed), bearing(obj.windBearing)]
  end

  def alert_messages
    message = ''
    append_network_notifications(message)
    append_alerts(message)
    append_nearest_storm_message(message)
    return message
  end

  private

  def make_flat_data(forecast)
    @flat_data = Hash.new(I18n.t('default_value'))
    set_flat_data_defaults if @@set_flat_data_defaults
    recursive_flat_data([], forecast)
  end

  def recursive_flat_data(keys, object)
    keys.pop if keys.last == 'data'
    if object.kind_of? Hash
      object.each_pair { |k,v| recursive_flat_data(keys + [k], v) }
    elsif object.kind_of? Array
      object.each_with_index { |v,i| recursive_flat_data(keys + [i.to_s], v) }
    else
      key = keys.last
      @flat_data[to_key(keys)] = case key
        when /error\Z/i then percentage(object)
        when /time\Z/i, 'expires' then time(@flat_data, object, keys)
        when /bearing\Z/i then bearing(object)
        when @@units_regexp then unit_message(object, $&)
        when 'icon' then @@icons[object]
        when 'moonPhase' then moon(object)
        when 'precipProbability'
          precipType = to_key(keys[0...-1] << 'precipType')
          if not @flat_data.has_key? precipType
            @flat_data[precipType] = I18n.t('precipitation.default')
          end
          percentage(object)
        when 'dewPoint' then unit_message(object, :temperature)
        when 'cloudCover' then percentage(object)
        when 'humidity' then percentage(object)
        when 'visibility' then unit_message(object, :distance)
        else object
      end
    end
  end

  def set_flat_data_defaults
    # ruby versions prior to 2.3.0 do not support hash default arguments in sprintf.
    # this means that this app will crash if the output format specification
    # asks for attributes which are not present in the received data.
    # we initialise the hash with all values listed in the api-specification.
    layout = Hashie::Mash.new(YAML.load(File.read(File.join(@@data_dir, 'api.yml'))))
    set_flat_data_default([], layout['structure'], layout)
  end

  def set_flat_data_default(keys, object, layout)
    if object.kind_of? Hash
      object.each_pair do |key, value|
        set_flat_data_default(keys + [key], value, layout)
      end
    elsif object.kind_of? Array
      size, elem = object
      0.upto(size).each do |i|
        set_flat_data_default(keys + [i.to_s], elem, layout)
      end
    else
      layout[object].each do |entry|
        @flat_data[to_key(keys + [entry])] = I18n.t('default_value')
      end
    end
  end

  def to_key(key_parts)
    key_parts.join('.').to_sym
  end

  def time(store, time, keys)
    time = Time.at(time)
    time_formats = I18n.backend.__send__(:translations)[:en][:time][:formats]
    default = 'NA'
    time_formats.each do |name, format|
      default = time.strftime(format) if name == :default
      store[to_key(keys+[name])] = time.strftime(format)
    end
    return default
  end

  def unit_message(value, type)
    type[0] = type[0].downcase if type.kind_of? String
    I18n.t('unit_message') % [value.to_s, unit(type.to_sym)]
  end

  def percentage(value)
    I18n.t('percent') % (100*value)
  end

  def append_network_notifications(message)
    if data.flags.has_key? DARKSKY_OFFLINE
      info = data.flags[DARKSKY_OFFLINE].inspect
      message << I18n.t('darksky.offline').yellow % info
    end
  end

  def append_alerts(message)
    data.alerts!.each do |alert|
      message << alert_message(alert).red
    end
  end

  def alert_message(alert)
    message = alert_title(alert)
    message << "\n"
    message << alert.description << "\n" if alert.description?
    message << alert.uri << "\n" if alert.uri?
  end

  def alert_title(alert)
    if alert.expires?
      alert_time = I18n.l(Time.at(alert.expires))
      if alert.title?
        title = I18n.t('alert.titled.with_time') % [alert.title, alert_time]
      else
        title = I18n.t('alert.simple.with_time') % alert_time
      end
    elsif alert.title?
      title = I18n.t('alert.titled.base') % alert.title
    else
      title = I18n.t('alert.simple.base')
    end
    return title.bold
  end

  def append_nearest_storm_message(message)
    if data.currently.nearestStormDistance! < options.storm_warn_distance
      message << I18n.t('storm.near').yellow % [
        forecast.currently.nearestStormDistance, unit(:distance),
        (options.location || @flat_data[:coordinates]),
        deg_to_compass(forecast.currently.nearestStormBearing)
      ]
    end
  end
end

Forecast.setup
