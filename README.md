# rb-forecast

This is a weather forecast app for your shell.
It gets its forecasts from http://forecast.io and you need your own API key
to use it. You can run it with `./weather.rb --key <your-api-key> --loc
<your city>`, or you can use `--lat` and `--long` for coordinate input (in
decimal notation) instead.

rb-forecast uses a Google API for location resolution. You can save your
location and forecast.io API key as default using `--save all`. 

## Installation

You need at least Ruby 2.0 to run this program. Ruby 2.3 is recommended for
optimal support.

You need the ruby-gems `hashie` and `i18n`. The gem `colorize` is
recommended. Install these with

`gem install hashie i18n colorize`

You also need an API key for the Forecast API. Get one at
`https://developer.forecast.io/`

## Usage

You can specify a forecast config file using `--config name`. You find
example format files in `config/format`. The file can consist of any text
and references to the data in sprintf notation. The full list of attributes
is specified in `config/api.yml`. In addition to the forecast.io attributes,
the app allows access to `location`, `longitude`, `latitude`, `coordinates`,
and `position`; the latter is the location or else the coordinates if no
place name is available. All times have sub-attributes as listed in the
matching localization file under the time attribute. Wind bearings and many
numeric values are available in short and long format.

## Format files

## Contributing

### Known Bugs

Some icons are incorrectly recognized as two characters and cause problems
with the markup.

### Localization

The Forecast.io API supports many languages. In order to localize this app,
you need to adjust files in `config/format`. There you find YAML files
`.yml`, which you can adapt by changing the language argument and the
requested units. You will also want to create a custom format file. In
addition, your language needs to be supported by the application itself.
Copy your language's localization file from
`https://github.com/svenfuchs/rails-i18n/tree/master/rails/locale` into
`confg/locales` and add the entries you see in the provided files. Take care
not to forget the time expressions, which in the downloaded file you find at
the very bottom!
