require 'rails_helper'

RSpec.describe Onsi::Params do
  let(:params) do
    ActionController::Parameters.new(
      data: {
        type: 'person',
        attributes: {
          name: 'Madison',
          foo: 'Bar',
          nicknames: [
            'Maddie',
            'Mads'
          ]
        },
        relationships: {
          person: {
            data: {
              type: 'person',
              id: '7'
            }
          },
          access_tokens: {
            data: [
              { type: 'access_token', id: '1' },
              { type: 'access_token', id: '2' }
            ]
          }
        }
      }
    )
  end

  describe '.parse' do
    context 'given valid params' do
      subject { described_class.parse(params, %i[name nicknames], %i[person access_tokens]) }

      it { expect { subject }.to_not raise_error }

      it { expect(subject.attributes).to eq('name' => 'Madison', 'nicknames' => %w[Maddie Mads]) }

      it { expect(subject.relationships).to eq(person_id: '7', access_token_ids: %w[1 2]) }
    end

    context 'given an optional relationship and nil data' do
      let(:params) do
        ActionController::Parameters.new(
          data: {
            type: 'person',
            attributes: {
              name: 'Maddie',
              foo: 'Bar'
            },
            relationships: {
              person: {
                data: nil
              },
              access_tokens: {
                data: [
                  { type: 'access_token', id: '1' },
                  { type: 'access_token', id: '2' }
                ]
              }
            }
          }
        )
      end

      subject { described_class.parse(params, %w[name], %w[?person access_tokens]) }

      it { expect { subject }.to_not raise_error }

      it { expect(subject.relationships).to eq(person_id: nil, access_token_ids: %w[1 2]) }
    end

    context 'given included relationship data' do
      let(:params) do
        ActionController::Parameters.new(
          data: {
            type: 'person',
            attributes: {
              name: 'Maddie'
            },
            relationships: {
              organization: {
                data: {
                  type: 'organization',
                  id: '1'
                }
              },
              email: {
                data: {
                  source: '/included/email/1'
                }
              },
              phone_number: {
                data: {
                  source: '/included/phone_number'
                }
              },
              comment: {
                data: {
                  source: '/included/comment/*'
                }
              }
            }
          },
          included: [
            {
              type: 'email',
              id: '1',
              attributes: {
                address: 'test@example.test'
              }
            },
            {
              type: 'email',
              id: '2',
              attributes: {
                address: 'comment-email@example.test'
              }
            },
            {
              type: 'phone_number',
              attributes: {
                number: '(123) 555-1234'
              }
            },
            {
              type: 'comment',
              id: '1',
              attributes: {
                content: 'Comment One'
              },
              relationships: {
                post: {
                  data: {
                    type: 'post',
                    id: '1'
                  }
                },
                email: {
                  data: {
                    source: '/included/email/2'
                  }
                }
              }
            },
            {
              type: 'comment',
              id: '2',
              attributes: {
                content: 'Comment Two'
              },
              relationships: {
                post: {
                  data: {
                    type: 'post',
                    id: '2'
                  }
                }
              }
            }
          ]
        )
      end

      let(:relationships) do
        [
          :organization,
          {
            email: [:address],
            phone_number: [:number]
          },
          {
            comment: [
              :content,
              {
                relationships: [:post]
              },
              {
                relationships: [
                  { email: [:address] }
                ]
              }
            ]
          }
        ]
      end

      subject { described_class.parse(params, %w[name], relationships) }

      it { expect { subject }.to_not raise_error }

      it { expect(subject.flatten.dig('email', 'address')).to eq 'test@example.test' }

      it { expect(subject.flatten.dig('phone_number', 'number')).to eq '(123) 555-1234' }

      it { expect(subject.flatten.dig('organization_id')).to eq '1' }

      it { expect(subject.flatten.dig('comment', '1', 'content')).to eq 'Comment One' }

      it { expect(subject.flatten.dig('comment', '1', 'post_id')).to eq '1' }

      it { expect(subject.flatten.dig('comment', '1', 'email', 'address')).to eq 'comment-email@example.test' }

      it { expect(subject.flatten.dig('comment', '2', 'content')).to eq 'Comment Two' }

      it { expect(subject.flatten.dig('comment', '2', 'post_id')).to eq '2' }

      it { expect(subject.flatten.dig('comment', '2', 'email', 'address')).to be_nil }
    end

    context 'given an invalid relationships' do
      let(:params) do
        ActionController::Parameters.new(
          data: {
            type: 'person',
            attributes: {
              name: 'Maddie'
            },
            relationships: {
              person: {
                data: {
                  type: 'person',
                  id: '7'
                }
              }
            }
          }
        )
      end

      let(:relationships) do
        [
          :person,
          123
        ]
      end

      it 'raises an error for invalid relationships' do
        expect { described_class.parse(params, [], relationships) }.to raise_error(ArgumentError) do |error|
          expect(error.message).to eq 'Unexpected type for relationship 123'
        end
      end
    end

    context 'given an optional relationship and empty array' do
      let(:params) do
        ActionController::Parameters.new(
          data: {
            type: 'person',
            attributes: {
              name: 'Maddie',
              foo: 'Bar'
            },
            relationships: {
              person: {
                data: {
                  type: 'person',
                  id: '7'
                }
              },
              access_tokens: {
                data: []
              }
            }
          }
        )
      end

      subject { described_class.parse(params, [:name], %w[person ?access_tokens]) }

      it { expect { subject }.to_not raise_error }

      it { expect(subject.relationships).to eq(person_id: '7', access_token_ids: []) }
    end

    context 'given an expected key not in the body' do
      let(:params) do
        ActionController::Parameters.new(
          data: {
            type: 'person',
            attributes: {
              name: 'Maddie'
            },
            relationships: {
              person: {
                data: nil
              },
              access_tokens: {
                data: [
                  { type: 'access_token', id: '1' },
                  { type: 'access_token', id: '2' }
                ]
              }
            }
          }
        )
      end

      subject { described_class.parse(params, %w[name foo], %w[?person access_tokens]) }

      it { expect { subject }.to_not raise_error }
    end
  end

  describe '.parse_json' do
    context 'given valid params' do
      let(:body) do
        JSON.dump(
          data: {
            type: 'person',
            attributes: {
              name: 'Maddie'
            },
            relationships: {
              person: {
                data: {
                  type: 'person',
                  id: '7'
                }
              },
            }
          }
        )
      end

      context 'given a raw string' do
        subject { described_class.parse_json(body, %i[name], %i[person]) }

        it { expect(subject.attributes).to eq('name' => 'Maddie') }

        it { expect(subject.relationships).to eq(person_id: '7') }
      end

      context 'given a string io' do
        subject { described_class.parse_json(StringIO.new(body), %i[name], %i[person]) }

        it { expect(subject.attributes).to eq('name' => 'Maddie') }

        it { expect(subject.relationships).to eq(person_id: '7') }
      end
    end
  end

  describe '#flatten' do
    subject { described_class.parse(params, [:name], %i[person access_tokens]) }

    it 'merges attributes & relationships' do
      expect(subject.flatten).to eq(
        'name' => 'Madison',
        'person_id' => '7',
        'access_token_ids' => %w[1 2]
      )
    end
  end

  describe '#require' do
    subject { described_class.parse(params, [:name], %i[person access_tokens]) }

    it 'returns a valid attribute' do
      expect(subject.require(:name)).to eq 'Madison'
      expect(subject.require('name')).to eq 'Madison'
    end

    it 'raises on missing key' do
      expect { subject.require(:missing) }.to raise_error Onsi::Params::MissingReqiredAttribute do |err|
        expect(err.attribute).to eq 'missing'
      end
    end
  end

  describe '#fetch' do
    subject { described_class.parse(params, [:name], %i[person access_tokens]) }

    it 'returns a valid attribute' do
      expect(subject.fetch(:name)).to eq 'Madison'
    end

    it 'returns nil' do
      expect(subject.fetch(:baz)).to be_nil
    end

    it 'returns default' do
      expect(subject.fetch(:baz, :testing)).to eq :testing
    end
  end

  describe '#safe_fetch' do
    context 'given a valid person' do
      let(:person) { Person.create! first_name: 'Test', last_name: 'Person' }

      subject { described_class.new({}, person_id: person.id.to_s) }

      it { expect(subject.safe_fetch(:person_id) { |id| Person.find(id) }).to eq person }
    end

    context 'given a missing person' do
      subject { described_class.new({}, person_id: '4000') }

      it 'raises an Onsi::Params::RelationshipNotFound error' do
        expect do
          subject.safe_fetch(:person_id) { |id| Person.find(id) }
        end.to raise_error Onsi::Params::RelationshipNotFound
      end
    end
  end

  describe '#transform' do
    subject { described_class.parse(params, %i[name]) }

    it 'runs through the transform block' do
      subject.transform(:name) { |name| "tested transform #{name}" }
      expect(subject.flatten[:name]).to eq 'tested transform Madison'
    end
  end

  describe '#default' do
    subject { described_class.parse(params, %i[name missing]) }

    it 'runs through the default block' do
      subject.default(:missing, -> { :foo })
      expect(subject.flatten[:missing]).to eq :foo
    end

    it 'has the default value' do
      subject.default(:missing, 'bar')
      expect(subject.flatten[:missing]).to eq 'bar'
    end
  end
end
