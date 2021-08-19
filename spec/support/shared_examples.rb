# frozen_string_literal: true

RSpec.shared_examples 'successful billing API response' do
  it 'the request is successful' do
    expect(metrics_response.status).to eq 200
  end

  it 'the cost metrics are available' do
    expect(metrics_response.body).to include(cost_metrics_values)
  end
end
