require 'rails_helper'

RSpec.describe Onsi::Graph::Version do
  let(:version) { AppGraph.versions.first }

  describe '#route' do
    it { expect { version.route('emails/43892/messages/943432') }.to_not raise_error }

    context 'given a message root' do
      it { expect(version.route('emails/43892/messages')[0].edge).to eq AppGraph::V2019_07_01::Edges::PersonEmails }
      it { expect(version.route('emails/43892/messages')[0].id).to eq '43892' }
      it { expect(version.route('emails/43892/messages')[1].edge).to eq AppGraph::V2019_07_01::Edges::EmailMessages }
      it { expect(version.route('emails/43892/messages')[1].id).to be_nil }
    end

    context 'given a message id' do
      it { expect(version.route('emails/43892/messages/943432')[0].edge).to eq AppGraph::V2019_07_01::Edges::PersonEmails }
      it { expect(version.route('emails/43892/messages/943432')[0].id).to eq '43892' }
      it { expect(version.route('emails/43892/messages/943432')[1].edge).to eq AppGraph::V2019_07_01::Edges::EmailMessages }
      it { expect(version.route('emails/43892/messages/943432')[1].id).to eq '943432' }
    end
  end
end
