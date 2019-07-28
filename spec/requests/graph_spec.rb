require 'rails_helper'

RSpec.describe 'Graph', type: :request do
  subject { response }

  let!(:person)  { Person.create! first_name: 'Test', last_name: 'Person' }
  let!(:email)   { person.emails.create(address: 'test@example.com') }
  let!(:message) { email.messages.create(sent_at: 1.hour.ago, body: 'Test Message') }

  let(:body) { JSON.parse(response.body) }

  describe 'GET /graph/v1/2019-07-01/emails/1/messages' do
    before { get "/graph/v1/2019-07-01/emails/#{email.id}/messages" }

    it { is_expected.to have_http_status :ok }

    it { expect(body.dig('data').count).to eq 1 }

    it { expect(body.dig('data', 0, 'type')).to eq 'message' }

    it { expect(body.dig('data', 0, 'id')).to eq message.id.to_s }
  end

  describe 'GET /graph/v1/2019-07-01/emails/1/messages/1' do
    before { get "/graph/v1/2019-07-01/emails/#{email.id}/messages/#{message.id}" }

    it { is_expected.to have_http_status :ok }

    it { expect(body.dig('data', 'type')).to eq 'message' }

    it { expect(body.dig('data', 'id')).to eq message.id.to_s }
  end

  describe 'GET /graph/v1/2019-07-01/emails/1' do
    before { get "/graph/v1/2019-07-01/emails/#{email.id}" }

    it { is_expected.to have_http_status :ok }

    it { expect(body.dig('data', 'type')).to eq 'email' }

    it { expect(body.dig('data', 'id')).to eq email.id.to_s }
  end

  describe 'GET /graph/v1/2019-07-01/emails' do
    before { get '/graph/v1/2019-07-01/emails' }

    it { is_expected.to have_http_status :ok }

    it { expect(body.dig('data').count).to eq 1 }

    it { expect(body.dig('data', 0, 'type')).to eq 'email' }

    it { expect(body.dig('data', 0, 'id')).to eq email.id.to_s }
  end

  describe 'GET /graph/v1/2019-07-01/' do
    before { get '/graph/v1/2019-07-01/' }

    it { is_expected.to have_http_status :ok }

    it { expect(body.dig('data', 'type')).to eq 'person' }

    it { expect(body.dig('data', 'id')).to eq person.id.to_s }
  end
end
