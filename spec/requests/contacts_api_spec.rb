require 'rails_helper'

RSpec.describe 'Contacts Paginated API', type: :request do
  let!(:person) { Person.create! first_name: 'Test', last_name: 'Person' }

  before do
    50.times do |i|
      person.contacts.create(value: "contact-#{i}")
    end
  end

  describe 'GET /api/v1/people/1/contacts' do
    before { get "/api/v1/people/#{person.id}/contacts" }

    subject { JSON.parse(response.body) }

    it { expect(response).to have_http_status 200 }
  end

  describe 'GET /api/v1/people/1/contacts?cursor=' do
    subject { JSON.parse(response.body) }

    it 'returns the expected results' do
      cursor = nil
      10.times do |i|
        get "/api/v1/people/#{person.id}/contacts?per_page=5&cursor=#{cursor}"

        json = JSON.parse(response.body)

        cursor = json.dig('meta', 'pagination', 'cursor')

        expect(response).to have_http_status 200

        expect(json.dig('data').count).to eq 5

        expect(json.dig('data').first.dig('id')).to eq(((i * 5) + 1).to_s)
      end

      get "/api/v1/people/#{person.id}/contacts?per_page=5&cursor=#{cursor}"

      expect(response).to have_http_status 200

      json = JSON.parse(response.body)

      expect(json.dig('data').count).to eq 0
    end

    it 'returns a 400 with an invalid cursor' do
      get "/api/v1/people/#{person.id}/contacts?per_page=5&cursor=foo-bar"

      expect(response).to have_http_status 400

      expect(subject.dig('errors', 0, 'detail')).to eq 'invalid cursor format'
    end
  end
end
