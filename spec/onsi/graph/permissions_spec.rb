require 'rails_helper'

RSpec.describe Onsi::Graph::Permissions do
  describe '.from' do
    context 'given a class' do
      it { expect(described_class.from(nil, Onsi::Graph::Permissions::ReadOnly)).to eq Onsi::Graph::Permissions::ReadOnly }
    end

    context 'given a symbol' do
      it { expect(described_class.from(nil, :read_only)).to eq Onsi::Graph::Permissions::ReadOnly }
    end

    context 'given an invalid type' do
      it 'raises an error' do
        expect { described_class.from(nil, 1) }.to raise_error do |e|
          expect(e.message).to eq 'unexpected permissions type'
        end
      end
    end
  end

  describe '#can_read?' do
    it { expect(Onsi::Graph::Permissions.new(nil, nil).can_read?).to eq false }
  end

  describe '#can_create?' do
    it { expect(Onsi::Graph::Permissions.new(nil, nil).can_create?).to eq false }
  end

  describe '#can_update?' do
    it { expect(Onsi::Graph::Permissions.new(nil, nil).can_update?).to eq false }
  end

  describe '#can_destroy?' do
    it { expect(Onsi::Graph::Permissions.new(nil, nil).can_destroy?).to eq false }
  end
end
