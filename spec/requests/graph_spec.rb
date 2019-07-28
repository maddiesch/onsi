require 'rails_helper'

RSpec.describe 'Graph', type: :request do
  subject { response }

  describe 'GET /graph/v1/2019-07-01' do
    before { get '/graph/v1/2019-07-01' }

    it { is_expected.to have_http_status :ok }
  end
end
