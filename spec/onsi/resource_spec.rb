require 'rails_helper'

RSpec.describe Onsi::Resource do
  describe 'validation' do
    context 'missing Onsi::Model include' do
      class TestClass; end

      it 'raises an error when creating' do
        expect { Onsi::Resource.new(TestClass.new) }.to raise_error Onsi::Resource::InvalidResourceError
      end
    end

    context 'invalid includes' do
      it 'raises an error when creating' do
        person = Person.create!(first_name: 'Test', last_name: 'Person')
        includes = { foo: [] }
        expect do
          Onsi::Resource.new(person, :v1, includes: includes)
        end.to raise_error Onsi::Resource::InvalidResourceError
      end
    end
  end
end
