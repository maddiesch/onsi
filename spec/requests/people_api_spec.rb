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

  describe 'POST /api/v1/people' do
    subject { JSON.parse(response.body) }

    context 'given a valid post body' do
      let(:params) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              first_name: 'Maddie',
              last_name: 'Schipper'
            },
            relationships: {
              email: {
                data: {
                  source: '/included/email'
                }
              }
            }
          },
          included: [
            {
              type: 'email',
              attributes: {
                address: 'me@maddiesch.com'
              }
            }
          ]
        )
      end

      before { post '/api/v1/people', params: params }

      it { expect(response).to have_http_status :created }

      it { expect(subject.dig('data')).to be_a(Array) }

      it { expect(subject.dig('data', 0, 'type')).to eq 'person' }

      it { expect(subject.dig('data', 1, 'type')).to eq 'email' }
    end

    context 'given a missing email include' do
      let(:params) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              first_name: 'Maddie',
              last_name: 'Schipper'
            },
            relationships: {
              email: {
                data: {
                  source: '/included/email/1'
                }
              }
            }
          },
          included: []
        )
      end

      before { post '/api/v1/people', params: params }

      it { expect(response).to have_http_status :bad_request }

      it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_include' }

      it { expect(subject.dig('errors', 0, 'meta', 'source')).to eq '/included/email/1' }

      it { expect(subject.dig('errors', 0, 'detail')).to eq 'Invalid Source: Unable to find included.' }
    end

    context 'given an email with no id' do
      let(:params) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              first_name: 'Maddie',
              last_name: 'Schipper'
            },
            relationships: {
              email: {
                data: {
                  source: '/included/email/1'
                }
              }
            }
          },
          included: [
            {
              type: 'email',
              attributes: {
                address: 'me@maddiesch.com'
              }
            }
          ]
        )
      end

      before { post '/api/v1/people', params: params }

      it { expect(response).to have_http_status :bad_request }

      it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_parameter' }

      it { expect(subject.dig('errors', 0, 'meta', 'param')).to eq 'id' }
    end

    context 'given an email with a missmatched id' do
      let(:params) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              first_name: 'Maddie',
              last_name: 'Schipper'
            },
            relationships: {
              email: {
                data: {
                  source: '/included/email/1'
                }
              }
            }
          },
          included: [
            {
              type: 'email',
              id: '2',
              attributes: {
                address: 'me@maddiesch.com'
              }
            }
          ]
        )
      end

      before { post '/api/v1/people', params: params }

      it { expect(response).to have_http_status :bad_request }

      it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_include' }

      it { expect(subject.dig('errors', 0, 'meta', 'source')).to eq '/included/email/1' }

      it { expect(subject.dig('errors', 0, 'detail')).to eq 'Invalid Source: Unable to find included.' }
    end

    context 'given an email with no address' do
      let(:params) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              first_name: 'Maddie',
              last_name: 'Schipper'
            },
            relationships: {
              email: {
                data: {
                  source: '/included/email'
                }
              }
            }
          },
          included: [
            {
              type: 'email',
              attributes: {
                example: 'foo'
              }
            }
          ]
        )
      end

      before { post '/api/v1/people', params: params }

      it { expect(response).to have_http_status :bad_request }

      it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_attribute' }

      it { expect(subject.dig('errors', 0, 'meta', 'attribute')).to eq 'email/address' }
    end

    context 'given a missing source' do
      let(:params) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              first_name: 'Maddie',
              last_name: 'Schipper'
            },
            relationships: {
              email: {
                data: {
                  source: ''
                }
              }
            }
          },
          included: [
            {
              type: 'email',
              attributes: {
                address: 'me@maddiesch.com'
              }
            }
          ]
        )
      end

      before { post '/api/v1/people', params: params }

      it { expect(response).to have_http_status :bad_request }

      it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_include' }

      it { expect(subject.dig('errors', 0, 'meta', 'source')).to eq '' }

      it { expect(subject.dig('errors', 0, 'detail')).to eq 'Invalid Source: /' }
    end

    context 'given an invalid source' do
      let(:params) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              first_name: 'Maddie',
              last_name: 'Schipper'
            },
            relationships: {
              email: {
                data: {
                  source: '/foo/email'
                }
              }
            }
          },
          included: [
            {
              type: 'email',
              attributes: {
                address: 'me@maddiesch.com'
              }
            }
          ]
        )
      end

      before { post '/api/v1/people', params: params }

      it { expect(response).to have_http_status :bad_request }

      it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_include' }

      it { expect(subject.dig('errors', 0, 'meta', 'source')).to eq '/foo/email' }

      it { expect(subject.dig('errors', 0, 'detail')).to eq 'Invalid Source: /foo is not included' }
    end

    context 'given an multiple emails' do
      let(:params) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              first_name: 'Maddie',
              last_name: 'Schipper'
            },
            relationships: {
              email: {
                data: {
                  source: '/included/email'
                }
              }
            }
          },
          included: [
            {
              type: 'email',
              attributes: {
                address: 'me@maddiesch.com'
              }
            },
            {
              type: 'email',
              attributes: {
                address: 'me@maddiesch.com'
              }
            }
          ]
        )
      end

      before { post '/api/v1/people', params: params }

      it { expect(response).to have_http_status :bad_request }

      it { expect(subject.dig('errors', 0, 'code')).to eq 'missing_include' }

      it { expect(subject.dig('errors', 0, 'meta', 'source')).to eq '/included/email' }

      it { expect(subject.dig('errors', 0, 'detail')).to eq 'Invalid Source: Unable to disambiguate included. email' }
    end
  end
end
