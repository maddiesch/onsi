require 'rails_helper'

RSpec.describe 'Comments API', type: :request do
  let!(:person)   { Person.create! first_name: 'Test', last_name: 'Person' }
  let!(:email)    { person.emails.create(address: 'test@example.com') }
  let!(:message)  { email.messages.create(sent_at: 1.hour.ago, body: 'Test Message') }

  let!(:comment1) { Comment.create!(message: message, body: 'Test Comment One') }
  let!(:comment2) { Comment.create!(message: message, body: 'Test Comment Two') }
  let!(:comment3) { Comment.create!(message: message, body: 'Test Comment One Reply', parent: comment1) }

  describe 'GET /api/v1/messages/1/comments' do
    before { get "/api/v1/messages/#{message.id}/comments" }

    subject { JSON.parse(response.body) }

    it { expect(subject.dig('data').count).to eq 3 }
    it { expect(subject.dig('data', 0, 'relationships', 'children', 'data', 0, 'id')).to eq comment3.id.to_s }
    it { expect(subject.dig('data', 0, 'relationships', 'parent')).to_not be_nil }
    it { expect(subject.dig('data', 0, 'relationships', 'parent', 'data')).to be_nil }
    it { expect(subject.dig('data', 1, 'relationships', 'children', 'data')).to eq [] }
  end
end
