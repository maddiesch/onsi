module Onsi
  module Errors
    class BaseError < StandardError; end

    class UnknownVersionError < BaseError
      attr_reader :klass, :version

      def initialize(klass, version)
        @klass = klass
        @version = version
      end

      def message
        "Unsupported version #{version} for #{klass.name}"
      end
    end
  end
end
