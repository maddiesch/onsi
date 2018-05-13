require 'rails_helper'

RSpec.describe 'People API', type: :request do
  let!(:person1) { Person.create! first_name: 'Test', last_name: 'Person 1', birthdate: Date.new(1980, 4, 18) }
  let!(:person2) { Person.create! first_name: 'Test', last_name: 'Person 2' }

  describe 'GET /api/v1/people' do
    before { get '/api/v1/people' }

    subject { JSON.parse(response.body) }

    it { expect(response).to have_http_status 200 }
    it { expect(subject['data']).to be_a(Array) }
    it { expect(subject['data'].count).to eq 2 }
    it { expect(subject['data'][0]['type']).to eq 'person' }
    it { expect(subject['data'][0]['id']).to eq person1.id.to_s }
    it { expect(subject['data'][0]['attributes']).to have_key 'first_name' }
    it { expect(subject['data'][0]['attributes']).to have_key 'last_name' }
    it { expect(subject['data'][0]['attributes']).to_not have_key 'created_at' }
    it { expect(subject['data'][0]['attributes']).to_not have_key 'updated_at' }
    it { expect(subject['data'][0]['attributes']).to_not have_key 'birthdate' }
  end

  describe 'GET /api/v2/people' do
    before { get '/api/v2/people' }

    subject { JSON.parse(response.body) }

    it { expect(response).to have_http_status 200 }
    it { expect(subject['data']).to be_a(Array) }
    it { expect(subject['data'].count).to eq 2 }
    it { expect(subject['data'][0]['type']).to eq 'person' }
    it { expect(subject['data'][0]['id']).to eq person1.id.to_s }
    it { expect(subject['data'][0]['attributes']).to have_key 'first_name' }
    it { expect(subject['data'][0]['attributes']).to have_key 'last_name' }
    it { expect(subject['data'][0]['attributes']).to have_key 'created_at' }
    it { expect(subject['data'][0]['attributes']).to have_key 'updated_at' }
    it { expect(subject['data'][0]['attributes']).to have_key 'birthdate' }
  end
end
