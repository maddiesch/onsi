require 'rails_helper'

RSpec.describe 'CORS', type: :request do
  subject { response }

  describe 'OPTIONS /api/v1' do
    before { process :options, '/api/v1', headers: { 'Origin' => 'http://onsi-test.test/foo/bar' } }

    it { is_expected.to have_http_status :no_content }

    it { expect(response.headers['Access-Control-Allow-Credentials']).to eq 'true' }
    it { expect(response.headers['Access-Control-Expose-Headers']).to eq 'ETag, Link' }
    it { expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, POST, PATCH, PUT, DELETE, OPTIONS' }
    it { expect(response.headers['Access-Control-Allow-Origin']).to eq 'http://onsi-test.test/foo/bar' }
  end
end
