lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'faraday'
require 'egauge/configuration'
require 'faraday_middleware'
require 'json'
require 'egauge/constants'
require 'egauge/register'
require 'egauge/client'
require 'egauge/history'

