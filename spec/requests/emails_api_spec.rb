require 'rails_helper'

RSpec.describe 'Emails API', type: :request do
  let!(:person) { Person.create! first_name: 'Test', last_name: 'Person' }
  let!(:email)  { person.emails.create(address: 'test@example.com') }

  describe 'GET /api/v1/people/1/emails' do
    before { get "/api/v1/people/#{person.id}/emails" }

    subject { JSON.parse(response.body) }

    it { expect(response).to have_http_status 200 }
    it { expect(subject['data']).to be_a(Array) }
    it { expect(subject['data'].count).to eq 1 }
    it { expect(subject['data'][0]['type']).to eq 'email' }
    it { expect(subject['data'][0]['id']).to eq email.id.to_s }
    it { expect(subject['data'][0]['attributes']).to have_key 'address' }
    it { expect(subject['data'][0]['meta']).to have_key 'validated' }
    it { expect(subject['data'][0]['relationships']).to have_key 'person' }
    it { expect(subject['data'][0]['relationships']['person']).to have_key 'data' }
    it { expect(subject['data'][0]['relationships']['person']['data']).to have_key 'type' }
    it { expect(subject['data'][0]['relationships']['person']['data']).to have_key 'id' }
    it { expect(subject['data'][0]['relationships']['person']['data']['id']).to eq person.id.to_s }
  end

  describe 'GET /api/v1/people/1/emails/1' do
    before { get "/api/v1/people/#{person.id}/emails/#{email.id}" }

    subject { JSON.parse(response.body) }

    it { expect(response).to have_http_status 200 }
    it { expect(subject['data']).to be_a(Hash) }
  end
end
