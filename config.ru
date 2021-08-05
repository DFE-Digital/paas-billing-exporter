# frozen_string_literal: true

require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'
require 'prometheus/client'
require './billing'

use BillingCalculator

use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

run DefaultResponse.new
