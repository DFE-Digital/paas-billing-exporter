# frozen_string_literal: true

require 'billing'

def make_last_exit_status(code)
  `exit #{code}`
end

RSpec.describe CFWrapper do
  context 'when a shell command fails' do
    before do
      allow(described_class).to receive(:`).with("cf api #{API_URL} 2>&1").and_return('failed')
      make_last_exit_status 123
      allow(ENV).to receive(:fetch).with('PAAS_USERNAME').and_return('username')
      allow(ENV).to receive(:fetch).with('PAAS_PASSWORD').and_return('password')
    end

    after do
      make_last_exit_status 0
    end

    it 'raises an error' do
      described_class.init_paas_login
      expect { described_class.paas_token }.to raise_error(SystemCallError)
    end
  end

  context 'when the password contains a special character' do
    before do
      allow(ENV).to receive(:fetch).with('PAAS_USERNAME').and_return('username')
      allow(ENV).to receive(:fetch).with('PAAS_PASSWORD').and_return('password&')
      allow(described_class).to receive(:`).with("cf api #{API_URL} 2>&1")
      allow(described_class).to receive(:`).with('cf auth "username" "password&" 2>&1')
      allow(described_class).to receive(:`).with('cf oauth-token 2>&1').and_return('something')
    end

    it 'safely escapes it' do
      described_class.init_paas_login
      described_class.paas_token
      expect(described_class).to have_received(:`).with('cf auth "username" "password&" 2>&1')
    end
  end
end
