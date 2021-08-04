# frozen_string_literal: true

require 'billing'

FAKE_TOKEN = 'bearer eyJhbGciOiJSUzI.eyJqdGkiOiI3Z.SxafJ3STKA2CwOGy50Cwab7wd-twXU'

def mock_today_date
  allow(Time).to receive(:now) { Time.mktime(2021, 8, 3, 15, 0) }
end

def mock_api_response
  billing_api_response = File.read('spec/fixtures/billing_api_response.json')

  stub_request(:get, 'https://billing.london.cloud.service.gov.uk/billable_events')
    .with(query: { 'org_guid' => ORG_GUID, 'range_start' => '2021-08-02', 'range_stop' => '2021-08-03' })
    .with(headers: { 'Authorization' => FAKE_TOKEN })
    .to_return(body: billing_api_response)
end

RSpec.describe BillingCalculator do
  after do
    # The prometheus registry is a global object in the ruby process
    # It is not recreated for each test so the cost metric must be unregistered
    # after each test
    Prometheus::Client.registry.unregister(:cost)
  end

  context 'when the billing API returns data' do
    let(:token) { FAKE_TOKEN }
    let(:cost_metrics_values) do
      {
        { space: 'space0', resource_type: 'app', date: '2021-08-02' } => 0.03,
        { space: 'space0', resource_type: 'service', date: '2021-08-02' } => 0.03,
        { space: 'space1', resource_type: 'app', date: '2021-08-02' } => 0.1,
        { space: 'space1', resource_type: 'service', date: '2021-08-02' } => 0.07
      }
    end
    let(:my_instance) { instance_double(MyClass) }

    before do
      allow(ENV).to receive(:fetch).with('PAAS_USERNAME').and_return('username')
      allow(ENV).to receive(:fetch).with('PAAS_PASSWORD').and_return('password')
      mock_today_date
      mock_api_response
    end

    it 'updates the cost metrics' do
      billing_calculator = described_class.new(nil)
      billing_calculator.update_cost_metric(token)
      cost_metrics = billing_calculator.cost

      expect(cost_metrics.values).to eq(cost_metrics_values)
    end
  end

  context 'when SKIP_LOGIN is set' do
    before do
      allow(ENV).to receive(:[]).with('SKIP_LOGIN').and_return('tRuE')
    end

    it 'does not require paas credentials' do
      expect{described_class.new(nil)}.not_to raise_error
    end
  end
end
