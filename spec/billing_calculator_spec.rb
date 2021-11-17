# frozen_string_literal: true

require 'billing'
require 'rack/test'

RSpec.describe BillingCalculator do
  include Rack::Test::Methods
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  context 'when /metrics is accessed' do
    let(:metrics_response) { get '/metrics' }
    let(:cost_metrics_values) do
      <<~COST_METRICS
        cost{space="space0",resource_type="app"} 0.01
        cost{space="space0",resource_type="service"} 0.03
        cost{space="space1",resource_type="app"} 0.12
        cost{space="space1",resource_type="service"} 0.15
      COST_METRICS
    end

    before do
      mock_today_date
      mock_api_response('spec/fixtures/billing_api_response.json')
      allow(CFWrapper).to receive(:paas_token).and_return(FAKE_TOKEN)
    end

    after do
      # The prometheus registry is a global object in the ruby process. It is not recreated for each test
      # so the metrics must be unregistered after each test
      Prometheus::Client.registry.metrics.each do |m|
        Prometheus::Client.registry.unregister(m.name)
      end
    end

    context 'when PaaS credentials are set' do
      before do
        allow(ENV).to receive(:fetch).with('PAAS_USERNAME').and_return('username')
        allow(ENV).to receive(:fetch).with('PAAS_PASSWORD').and_return('password')
      end

      include_examples 'successful billing API response'
    end

    context 'when SKIP_LOGIN is set' do
      before do
        allow(ENV).to receive(:[]).with('SKIP_LOGIN').and_return('tRuE')
      end

      include_examples 'successful billing API response'
    end
  end

  context 'when any URL but /metrics is accessed' do
    before do
      allow(ENV).to receive(:[]).with('SKIP_LOGIN').and_return('tRuE')
    end

    after do
      # The prometheus registry is a global object in the ruby process. It is not recreated for each test
      # so the metrics must be unregistered after each test
      Prometheus::Client.registry.metrics.each do |m|
        Prometheus::Client.registry.unregister(m.name)
      end
    end

    let(:response) { get '/' }

    it 'the request is successful' do
      # The request to paas billing API is not stubbed. If it was attempted the test would fail.

      expect(response.status).to eq 200
    end
  end
end
