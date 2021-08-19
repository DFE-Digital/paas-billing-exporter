# frozen_string_literal: true

FAKE_TOKEN = 'bearer eyJhbGciOiJSUzI.eyJqdGkiOiI3Z.SxafJ3STKA2CwOGy50Cwab7wd-twXU'
BILLING_API_URL = 'https://billing.london.cloud.service.gov.uk/billable_events'

module Helpers
  def mock_today_date
    allow(Time).to receive(:now) { Time.mktime(2021, 8, 3, 15, 0) }
  end

  def mock_api_response(fixture_file)
    billing_api_response = File.read(fixture_file)

    stub_request(:get, BILLING_API_URL)
      .with(query: { 'org_guid' => ORG_GUID, 'range_start' => '2021-08-02', 'range_stop' => '2021-08-03' })
      .with(headers: { 'Authorization' => FAKE_TOKEN })
      .to_return(body: billing_api_response)
  end
end
