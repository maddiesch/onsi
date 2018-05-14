require 'rails_helper'

RSpec.describe Onsi::Controller do
  describe '.render_version' do
    class TestController
      include Onsi::Controller

      render_version :v2

      def render(opts)
        opts[:json].as_json
      end
    end

    class SubTestController < TestController; end

    class TestModel
      include Onsi::Model

      def id
        '1'
      end

      api_render(:v1) do
        attribute(:version) { 'v1' }
      end

      api_render(:v2) do
        attribute(:version) { 'v2' }
      end

      api_render(:v3) do
        attribute(:version) { 'v3' }
      end
    end

    describe 'render passed as option' do
      subject { TestController.new.render_resource(TestModel.new, version: :v1) }

      it { expect(subject.dig('data', 'attributes', 'version')).to eq 'v1' }
    end

    describe 'default' do
      subject { TestController.new.render_resource(TestModel.new) }

      it { expect(subject.dig('data', 'attributes', 'version')).to eq 'v2' }
    end

    describe 'default' do
      subject { TestController.new.render_resource(Onsi::Resource.new(TestModel.new, :v3), version: :v1) }

      it { expect(subject.dig('data', 'attributes', 'version')).to eq 'v3' }
    end

    describe 'SubTestController gets supers render_version' do
      it { expect(SubTestController.render_version).to eq :v2 }
    end
  end
end
