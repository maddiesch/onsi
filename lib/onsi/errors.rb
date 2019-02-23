module Onsi
  ##
  # Container module for custom errors
  module Errors
    ##
    # Base Error for all Onsi custom errors
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class BaseError < StandardError; end

    ##
    # An unknown version is requested to be rendered
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class UnknownVersionError < BaseError
      ##
      # The class that does not support the requested version.
      attr_reader :klass

      ##
      # The version requested that isn't supported
      attr_reader :version

      ##
      # Create a new UnknownVersionError
      #
      # @param klass (see #klass)
      #
      # @param version (see #version)
      def initialize(klass, version)
        super("Unsupported version #{version} for #{klass.name}")
        @klass = klass
        @version = version
      end
    end

    ##
    # Included Param Error
    #
    # @author Maddie Schipper
    # @since 1.1.0
    class IncludedParamError < BaseError
      ##
      # The path that failed to parse.
      attr_reader :path

      ##
      # @private
      #
      # Create a new IncludedParamError
      def initialize(message, path)
        super(message)
        @path = path
      end
    end
  end
end
