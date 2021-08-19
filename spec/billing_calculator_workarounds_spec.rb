# frozen_string_literal: true

require 'billing'
require 'rack/test'

RSpec.describe BillingCalculator do
  include Rack::Test::Methods
  let(:app) { Rack::Builder.parse_file('config.ru').first }
  let(:metrics_response) { get '/metrics' }

  before do
    mock_today_date
    allow(CFWrapper).to receive(:paas_token).and_return(FAKE_TOKEN)
    allow(ENV).to receive(:fetch).with('PAAS_USERNAME').and_return('username')
    allow(ENV).to receive(:fetch).with('PAAS_PASSWORD').and_return('password')
  end

  after do
    # The prometheus registry is a global object in the ruby process. It is not recreated for each test
    # so the metrics must be unregistered after each test
    Prometheus::Client.registry.metrics.each do |m|
      Prometheus::Client.registry.unregister(m.name)
    end
  end

  context 'when /metrics returns full day postgres data with inflated storage price' do
    let(:cost_metrics_values) do
      <<~COST_METRICS
        cost{space="space0",resource_type="service"} 2.98
      COST_METRICS
    end

    before do
      mock_api_response('spec/fixtures/billing_api_response_with_postgres_full_day.json')
    end

    include_examples 'successful billing API response'
  end

  context 'when /metrics returns partial day postgres data with inflated storage price' do
    let(:cost_metrics_values) do
      <<~COST_METRICS
        cost{space="space0",resource_type="service"} 2.46
      COST_METRICS
    end

    before do
      mock_api_response('spec/fixtures/billing_api_response_with_postgres_partial_day.json')
    end

    include_examples 'successful billing API response'
  end

  context 'when /metrics returns high price to show the 10% service charge' do
    let(:cost_metrics_values) do
      <<~COST_METRICS
        cost{space="space0",resource_type="service"} 1100.0
      COST_METRICS
    end

    before do
      mock_api_response('spec/fixtures/billing_api_response_with_high_cost.json')
    end

    include_examples 'successful billing API response'
  end
end
