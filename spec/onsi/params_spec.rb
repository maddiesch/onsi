require 'rails_helper'

RSpec.describe Onsi::Params do
  let(:params) do
    ActionController::Parameters.new(
      data: {
        type: 'person',
        attributes: {
          name: 'Skylar',
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
      subject { described_class.parse(params, [:name], %i[person access_tokens]) }

      it { expect { subject }.to_not raise_error }

      it { expect(subject.attributes).to eq('name' => 'Skylar') }

      it { expect(subject.relationships).to eq(person_id: '7', access_token_ids: %w[1 2]) }
    end
  end

  describe '#flatten' do
    subject { described_class.parse(params, [:name], %i[person access_tokens]) }

    it 'merges attributes & relationships' do
      expect(subject.flatten).to eq(
        'name' => 'Skylar',
        'person_id' => '7',
        'access_token_ids' => %w[1 2]
      )
    end
  end

  describe '#require' do
    subject { described_class.parse(params, [:name], %i[person access_tokens]) }

    it 'returns a valid attribute' do
      expect(subject.require(:name)).to eq 'Skylar'
      expect(subject.require('name')).to eq 'Skylar'
    end

    it 'raises on missing key' do
      expect { subject.require(:missing) }.to raise_error Onsi::Params::MissingReqiredAttribute do |err|
        expect(err.attribute).to eq :missing
      end
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
end
