require 'rails_helper'

RSpec.describe 'Messages API', type: :request do
  let!(:person)   { Person.create! first_name: 'Test', last_name: 'Person' }
  let!(:email)    { person.emails.create(address: 'test@example.com') }
  let!(:message)  { email.messages.create(sent_at: 1.hour.ago) }

  describe 'GET /api/v1/people/1/emails/1/messages' do
    before { get "/api/v1/people/#{person.id}/emails/#{email.id}/messages" }

    subject { JSON.parse(response.body) }

    it { expect(response).to have_http_status 200 }
    it { expect(subject['data']).to be_a(Array) }
    it { expect(subject['data'].count).to eq 1 }
    it { expect(subject['data'][0]['type']).to eq 'message' }
    it { expect(subject['data'][0]['id']).to eq message.id.to_s }
    it { expect(subject['data'][0]['attributes']).to have_key 'sent_at' }
    it { expect(subject['data'][0]['relationships']).to have_key 'email' }
    it { expect(subject['data'][0]['relationships']['email']).to have_key 'data' }
    it { expect(subject['data'][0]['relationships']['email']['data']).to have_key 'type' }
    it { expect(subject['data'][0]['relationships']['email']['data']).to have_key 'id' }
    it { expect(subject['data'][0]['relationships']['email']['data']['id']).to eq email.id.to_s }
  end
end
