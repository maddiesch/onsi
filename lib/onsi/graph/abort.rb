module Onsi
  module Graph
    ##
    # This error can be raised from anywhere in the Graph to immediately stop processing
    # the request and render the result.
    #
    # @example Authentication
    #   def authenticate!
    #     return if Person.current.present?
    #
    #     raise Onsi::Graph::Abort.new(401, {}, JSON.dump(error: 'Not authenticated'))
    #   end
    #
    # @author Maddie Schipper
    # @since 2.0.0
    class Abort < StandardError
      ##
      # The HTTP status code to return
      #
      # @return [Integer]
      attr_reader :status

      ##
      # The HTTP headers to return
      #
      # @return [Hash]
      attr_reader :headers

      ##
      # The Body to return
      #
      # @return [String, nil]
      attr_reader :body

      ##
      # Create a new {Onsi::Graph::Abort}
      #
      #
      def initialize(status, headers, body)
        @status = status
        @headers = headers
        @body = body.to_s
      end
    end
  end
end
