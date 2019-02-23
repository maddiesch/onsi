require 'rails_helper'

RSpec.describe Onsi::CORSHeaders do
  describe '.generate' do
    context 'given a valid env and an unknown origin' do
      let(:env) do
        {
          'HTTP_ORIGIN' => 'http://foo.bar/baz'
        }
      end

      subject { described_class.generate(env) }

      it { expect(subject['Access-Control-Allow-Credentials']).to eq 'true' }
      it { expect(subject['Access-Control-Expose-Headers']).to eq 'ETag, Link' }
      it { expect(subject['Access-Control-Allow-Methods']).to eq 'GET, POST, PATCH, PUT, DELETE, OPTIONS' }
      it { expect(subject['Access-Control-Allow-Origin']).to eq '*' }
      it { expect(subject['Vary']).to eq 'Accept, Accept-Encoding, Origin' }
    end

    context 'given a valid env and a known origin' do
      let(:env) do
        {
          'REQUEST_METHOD' => 'OPTIONS',
          'HTTP_ORIGIN' => 'http://localhost/baz'
        }
      end

      subject { described_class.generate(env) }

      it { expect(subject['Access-Control-Allow-Credentials']).to eq 'true' }
      it { expect(subject['Access-Control-Expose-Headers']).to eq 'ETag, Link' }
      it { expect(subject['Access-Control-Allow-Methods']).to eq 'GET, POST, PATCH, PUT, DELETE, OPTIONS' }
      it { expect(subject['Access-Control-Allow-Origin']).to eq 'http://localhost/baz' }
      it { expect(subject['Vary']).to eq 'Accept, Accept-Encoding, Origin' }
    end

    context 'given an invalid env' do
      let(:env) do
        {
          'REQUEST_METHOD' => 'OPTIONS',
          'HTTP_ORIGIN' => '127.0.0.1:1234'
        }
      end

      subject { described_class.generate(env) }

      it { expect(subject['Access-Control-Allow-Credentials']).to eq 'true' }
      it { expect(subject['Access-Control-Expose-Headers']).to eq 'ETag, Link' }
      it { expect(subject['Access-Control-Allow-Methods']).to eq 'GET, POST, PATCH, PUT, DELETE, OPTIONS' }
      it { expect(subject['Access-Control-Allow-Origin']).to eq '*' }
      it { expect(subject['Vary']).to eq 'Accept, Accept-Encoding, Origin' }
    end
  end
end
