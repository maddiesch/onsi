require 'rails_helper'

RSpec.describe Onsi::Graph::Model do
  subject { AppGraph }

  describe '#paths' do
    subject { AppGraph.new(nil) }

    it { expect { subject.paths }.to_not raise_error }

    it { puts; puts JSON.pretty_generate(subject.paths) }
  end

  describe '#call' do
    it { expect { subject.new(43_902).call }.to_not raise_error }
  end
end
