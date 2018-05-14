require 'rails_helper'

RSpec.describe Onsi::Resource do
  describe 'validation' do
    context 'missing Onsi::Model include' do
      class TestClass; end

      it 'raises an error when creating' do
        expect { Onsi::Resource.new(TestClass.new) }.to raise_error Onsi::Resource::InvalidResourceError
      end
    end
  end
end
