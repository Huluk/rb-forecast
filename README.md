# rb-forecast

This is a weather forecast app for your shell.
It gets its forecasts from http://forecast.io and you need your own API key
to use it. You can run it with `./weather.rb --key <your-api-key> --loc
<your city>`, or you can use `--lat` and `--long` for coordinate input (in
decimal notation) instead.

rb-forecast uses a Google API for location resolution. You can save your
location and forecast.io API key as default using `--save all`. 

## Format

You can specify a forecast format file using `--format <path>`. This format
file can consist of any text and references to the data, as exemplified in
`config/format.txt`. The full list of attributes is specified in
`config/api.yml`. In addition to the forecast.io attributes, the app gives
access to `location`, `longitude`, `latitude`, `coordinates`, and
`position`; the latter is the location or else the coordinates if no place
name is available.

## Requirements

rb-forecast needs the gems `hashie` and `i18n`, which you can install using
`gem install hashie` and `gem install i18n`, respectively. The gem
`colorize` is recommended for colored weather alerts. rb-forecast also
requires ruby version 2.0 – although I recommend version 2.3.0, because
everything before that does not support sprintf hash default values and uses
a workaround which may not keep up with API changes.

## Known Bugs

Some icons are incorrectly recognized as two characters and cause problems
with the markup.
