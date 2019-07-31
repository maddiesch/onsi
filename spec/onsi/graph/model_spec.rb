require 'rails_helper'

RSpec.describe Onsi::Graph::Model do
  subject { AppGraph }

  describe '#paths' do
    subject { AppGraph.new(nil) }

    it { expect { subject.paths }.to_not raise_error }
  end
end
