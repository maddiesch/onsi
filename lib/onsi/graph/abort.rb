module Onsi
  module Graph
    class Abort < StandardError
      attr_reader :status
      attr_reader :headers
      attr_reader :body

      def initialize(status, headers, body)
        @status = status
        @headers = headers
        @body = body
      end
    end
  end
end
