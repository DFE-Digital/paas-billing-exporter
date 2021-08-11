# frozen_string_literal: true

require 'billing'
require 'rack/test'

FAKE_TOKEN = 'bearer eyJhbGciOiJSUzI.eyJqdGkiOiI3Z.SxafJ3STKA2CwOGy50Cwab7wd-twXU'
BILLING_API_URL = 'https://billing.london.cloud.service.gov.uk/billable_events'

def mock_today_date
  allow(Time).to receive(:now) { Time.mktime(2021, 8, 3, 15, 0) }
end

def mock_api_response
  billing_api_response = File.read('spec/fixtures/billing_api_response.json')

  stub_request(:get, BILLING_API_URL)
    .with(query: { 'org_guid' => ORG_GUID, 'range_start' => '2021-08-02', 'range_stop' => '2021-08-03' })
    .with(headers: { 'Authorization' => FAKE_TOKEN })
    .to_return(body: billing_api_response)
end

RSpec.shared_examples 'successful billing API response' do
  it 'the request is successful' do
    expect(metrics_response.status).to eq 200
  end

  it 'the cost metrics are available' do
    expect(metrics_response.body).to include(cost_metrics_values)
  end
end

RSpec.describe BillingCalculator do
  include Rack::Test::Methods
  let(:app) { Rack::Builder.parse_file('config.ru').first }

  context 'when /metrics is accessed' do
    let(:metrics_response) { get '/metrics' }
    let(:cost_metrics_values) do
      <<~COST_METRICS
        cost{space="space0",resource_type="app"} 0.03
        cost{space="space0",resource_type="service"} 0.03
        cost{space="space1",resource_type="app"} 0.1
        cost{space="space1",resource_type="service"} 0.07
      COST_METRICS
    end

    before do
      mock_today_date
      mock_api_response
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

    let(:response) { get '/' }

    it 'the request is successful' do
      # The request to paas billing API is not stubbed. If it was attempted the test would fail.

      expect(response.status).to eq 200
    end
  end
end
