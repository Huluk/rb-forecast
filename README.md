# rb-forecast

This is a weather forecast app for your shell.
It gets its forecasts from http://forecast.io and you need your own API key
to use it. You can run it with `./weather.rb --key <your-api-key> --loc
<your city>`, or you can use `--lat` and `--long` for coordinate input (in
decimal notation) instead.

rb-forecast uses a Google API for location resolution. You can save your
location as default using `--save`. 

## Format

You can specify a forecast format file using `--format <path>`. This format
file can consist of any text and references to the data, as exemplified in
`config/format.txt`. The full list of attributes is specified in
`config/api.yml`.

## Requirements

rb-forecast needs the gem `hashie`, which you can install using `gem install
hashie`. It also requires ruby version 2.3.0 -- previous versions may crash
if an unspecified attribute is requested in the format file. Sorry for that,
I may implement support for earlier versions later.
