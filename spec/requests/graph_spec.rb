require 'rails_helper'

RSpec.describe 'Graph', type: :request do
  subject { response }

  let!(:person)  { Person.create! first_name: 'Test', last_name: 'Person' }
  let!(:email)   { person.emails.create(address: 'test@example.com') }
  let!(:message) { email.messages.create(sent_at: 1.hour.ago, body: 'Test Message') }

  let(:body) { JSON.parse(response.body) }

  describe 'GET /graph/v1/' do
    before { get '/graph/v1/' }

    it { is_expected.to have_http_status :found }

    it { expect(response.headers['Location']).to eq 'http://www.example.com/graph/v1/2019-07-01' }
  end

  describe 'GET /graph/v1/2019-07-01/emails/1/messages' do
    before { get "/graph/v1/2019-07-01/emails/#{email.id}/messages" }

    it { is_expected.to have_http_status :ok }

    it { expect(body.dig('data').count).to eq 1 }

    it { expect(body.dig('data', 0, 'type')).to eq 'message' }

    it { expect(body.dig('data', 0, 'id')).to eq message.id.to_s }
  end

  describe 'GET /graph/v1/2019-07-01//1/messages' do
    before { get "/graph/v1/2019-07-01//#{email.id}/messages" }

    it { is_expected.to have_http_status :not_found }
  end

  describe 'GET /graph/v1/2019-07-01/1/messages' do
    before { get "/graph/v1/2019-07-01/#{email.id}/messages" }

    it { is_expected.to have_http_status :not_found }
  end

  describe 'GET /graph/v1/2019-07-01/emails/0/messages' do
    before { get '/graph/v1/2019-07-01/emails/0/messages' }

    it { is_expected.to have_http_status :not_found }
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

  describe 'POST /graph/v1/2019-07-01/emails' do
    let(:params) do
      JSON.dump(
        data: {
          type: 'email',
          attributes: {
            address: 'testing+create@domain.test'
          }
        }
      )
    end

    before { post '/graph/v1/2019-07-01/emails', params: params }

    it { is_expected.to have_http_status :created }

    it { expect(person.emails.count).to eq 2 }
  end

  describe 'PATCH /graph/v1/2019-07-01/emails/1' do
    let(:params) do
      JSON.dump(
        data: {
          type: 'email',
          id: email.id.to_s,
          attributes: {
            address: 'testing+update@domain.test'
          }
        }
      )
    end

    before { patch "/graph/v1/2019-07-01/emails/#{email.id}", params: params }

    it { is_expected.to have_http_status :ok }

    it { expect(email.reload.address).to eq 'testing+update@domain.test' }
  end

  describe 'DELETE /graph/v1/2019-07-01/emails/1' do
    before { delete "/graph/v1/2019-07-01/emails/#{email.id}" }

    it { is_expected.to have_http_status :no_content }

    it { expect { email.reload }.to raise_error ActiveRecord::RecordNotFound }
  end
end
