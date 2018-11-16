require 'rails_helper'

RSpec.describe Onsi::Includes do
  describe '.new' do
    it { expect(described_class.new('foo,bar').included).to eq %i[foo bar] }
    it { expect(described_class.new(%w[foo bar]).included).to eq %i[foo bar] }
    it { expect(described_class.new(:foo).included).to eq %i[foo] }
    it { expect(described_class.new(nil).included).to eq %i[] }
    it { expect { described_class.new(3) }.to raise_error ArgumentError }
  end

  describe '#method_missing' do
    subject { described_class.new(nil) }

    it { expect { subject.foo }.to raise_error NoMethodError }
    it { expect { subject.fetch_foo }.to raise_error ArgumentError }
  end

  describe '#respond_to_missing?' do
    subject { described_class.new(nil) }

    it { expect(subject.respond_to?(:foo)).to eq false }
    it { expect(subject.respond_to?(:fetch_foo)).to eq true }
  end
end
