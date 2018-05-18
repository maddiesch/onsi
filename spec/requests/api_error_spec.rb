require 'rails_helper'

RSpec.describe 'API Error', type: :request do
  let!(:person) { Person.create! first_name: 'Test', last_name: 'Person' }
  let!(:email)  { person.emails.create(address: 'test@example.com') }

  subject { JSON.parse(response.body) }

  describe 'Onsi::Errors::UnknownVersionError' do
    before { get "/api/v2/people/#{person.id}/emails/#{email.id}" }

    it { expect(response).to have_http_status 400 }
    it { expect(subject['data']).to be_nil }
    it { expect(subject['errors']).to be_a(Array) }
    it { expect(subject.dig('errors', 0, 'status')).to eq '400' }
    it { expect(subject.dig('errors', 0, 'code')).to eq 'invalid_version' }
  end

  describe 'ActiveRecord::RecordNotFound' do
    before { get "/api/v1/people/#{person.id}/emails/#{email.id + 4}" }

    it { expect(response).to have_http_status 404 }
    it { expect(subject['data']).to be_nil }
    it { expect(subject['errors']).to be_a(Array) }
    it { expect(subject.dig('errors', 0, 'status')).to eq '404' }
    it { expect(subject.dig('errors', 0, 'code')).to eq 'not_found' }
  end

  describe 'StandardError' do
    before do
      expect_any_instance_of(PeopleController).to receive(:index) do
        raise ArgumentError, 'Passed 2, expected 4'
      end
      get "/api/v1/people"
    end

    it { expect(response).to have_http_status 500 }
    it { expect(subject['data']).to be_nil }
    it { expect(subject['errors']).to be_a(Array) }
    it { expect(subject.dig('errors', 0, 'status')).to eq '500' }
    it { expect(subject.dig('errors', 0, 'code')).to eq 'internal_server_error' }
  end

  describe 'ActiveRecord::RecordInvalid' do
    before do
      body = JSON.dump(
        data: {
          type: 'email',
          attributes: {
            address: 'foo'
          }
        }
      )
      post "/api/v1/people/#{person.id}/emails", params: body, headers: { 'Content-Type' => 'application/json' }
    end

    it { expect(response).to have_http_status 422 }
    it { expect(subject['data']).to be_nil }
    it { expect(subject['errors']).to be_a(Array) }
    it { expect(subject.dig('errors', 0, 'status')).to eq '422' }
    it { expect(subject.dig('errors', 0, 'code')).to eq 'validation_error' }
    it { expect(subject.dig('errors', 0, 'meta')).to eq('error' => 'invalid', 'value' => 'foo', 'param' => 'address') }
  end

  describe 'ActionController::ParameterMissing' do
    before do
      body = JSON.dump(
        data: {
          attributes: {
            address: 'test@test.com'
          }
        }
      )
      post "/api/v1/people/#{person.id}/emails", params: body, headers: { 'Content-Type' => 'application/json' }
    end

    it { expect(response).to have_http_status 400 }
    it { expect(subject['data']).to be_nil }
    it { expect(subject['errors']).to be_a(Array) }
    it { expect(subject.dig('errors', 0, 'status')).to eq '400' }
    it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_parameter' }
    it { expect(subject.dig('errors', 0, 'meta')).to eq('param' => 'type') }
  end

  describe 'Onsi::Params::RelationshipNotFound' do
    before do
      body = JSON.dump(
        data: {
          type: 'message',
          attributes: {
            body: 'messages'
          },
          relationships: {
            to: {
              data: {
                type: 'person',
                id: '0'
              }
            }
          }
        }
      )
      post "/api/v1/people/#{person.id}/emails/#{email.id}/messages",
           params: body,
           headers: { 'Content-Type' => 'application/json' }
    end

    it { expect(response).to have_http_status 400 }
    it { expect(subject['data']).to be_nil }
    it { expect(subject['errors']).to be_a(Array) }
    it { expect(subject.dig('errors', 0, 'status')).to eq '400' }
    it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_relationship' }
    it { expect(subject.dig('errors', 0, 'meta')).to eq('param' => 'to_id') }
  end

  describe 'Onsi::Params::MissingReqiredAttribute' do
    before do
      body = JSON.dump(
        data: {
          type: 'email',
          attributes: {
            foo: 'bar'
          }
        }
      )
      post "/api/v1/people/#{person.id}/emails", params: body, headers: { 'Content-Type' => 'application/json' }
    end

    it { expect(response).to have_http_status 400 }
    it { expect(subject['data']).to be_nil }
    it { expect(subject['errors']).to be_a(Array) }
    it { expect(subject.dig('errors', 0, 'status')).to eq '400' }
    it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_attribute' }
    it { expect(subject.dig('errors', 0, 'meta')).to eq('attribute' => 'address') }
  end
end
