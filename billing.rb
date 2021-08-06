#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require 'prometheus/client'
require 'byebug'

ORG = 'dfe'
BILLING_URL = 'https://billing.london.cloud.service.gov.uk'
ORG_GUID = '386a9502-d9b6-4aba-b3c3-ebe4fa3f963e'
API_URL = 'https://api.london.cloud.service.gov.uk'
PRECISION = 2

# Rack middleware to fetch billing data from the PaaS billing API and aggregate the data into prometheus metrics
class BillingCalculator
  def initialize(app)
    self.class.init_paas_login

    @app = app
    Prometheus::Client.registry.gauge(
      :cost,
      docstring: 'A counter representing PaaS cost per space and resource type on the previous day',
      labels: %i[space resource_type date]
    )
  end

  def self.init_paas_login
    @skip_login = false
    if ENV['SKIP_LOGIN'] && ENV['SKIP_LOGIN'].downcase == 'true'
      @skip_login = true
    else
      @paas_username = ENV.fetch('PAAS_USERNAME')
      @paas_password = ENV.fetch('PAAS_PASSWORD')
    end
  end

  def self.aggregate_cost(token)
    global_cost = calculate_cost yesterday_billing_data(
      token, range_start_yesterday, range_stop_today
    )
    metrics(global_cost).sort_by { |c| "#{c[:space]}-#{c[:resource_type]}" }
  end

  def self.update_cost_metric(token)
    cost_array = aggregate_cost(token)

    cost_metric = Prometheus::Client.registry.get(:cost)
    cost_array.each do |c|
      cost_metric.set(
        c[:price],
        labels: { space: c[:space], resource_type: c[:resource_type], date: range_start_yesterday }
      )
    end
  end

  def call(env)
    token = self.class.paas_token.strip
    self.class.update_cost_metric(token)

    @app.call(env)
  end

  def self.paas_token
    unless @skip_login
      system "cf api #{API_URL}"
      system "cf auth #{@paas_username} #{@paas_password}"
    end
    `cf oauth-token`
  end

  def self.range_start_yesterday
    (Time.now - 60 * 60 * 24).strftime('%Y-%m-%d')
  end

  def self.range_stop_today
    Time.now.strftime('%Y-%m-%d')
  end

  def self.prepare_uri(range_start, range_stop)
    uri = URI("#{BILLING_URL}/billable_events")
    params = {
      range_start: range_start,
      range_stop: range_stop,
      org_guid: ORG_GUID
    }
    uri.query = URI.encode_www_form(params)
    uri
  end

  def self.yesterday_billing_data(token, range_start, range_stop)
    uri = prepare_uri(range_start, range_stop)
    req = Net::HTTP::Get.new uri
    req['authorization'] = token

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    raise "Error in request to billing API: #{res.code} #{res.message} #{res.body}" if res.code != '200'

    JSON.parse(res.body)
  end

  def self.aggregate_price_details(event)
    price = 0
    event['price']['details'].each do |d|
      price += d['inc_vat'].to_f
    end
    price
  end

  def self.calculate_cost(billing_data)
    cost = {}
    billing_data.each do |details|
      cost[details['space_name']] ||= {}
      cost[details['space_name']][details['resource_type']] ||= 0
      cost[details['space_name']][details['resource_type']] += aggregate_price_details(details)
    end
    cost
  end

  def self.metrics(cost)
    metrics = []
    cost.each do |space, price_per_type|
      price_per_type.each do |t, price|
        metrics << { space: space, resource_type: t, price: price.round(PRECISION) }
      end
    end
    metrics
  end
end

# Rack middleware to present a default HTTP response at the end of Rack processing
class DefaultResponse
  def call(_env)
    status  = 200
    headers = { 'Content-Type' => 'text/html' }
    body    = ["Prometheus metrics updated. See: <a href='/metrics'>/metrics<a>"]

    [status, headers, body]
  end
end
