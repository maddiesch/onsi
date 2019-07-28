require_relative '../resource'
require_relative '../paginate'

module Onsi
  module Graph
    ##
    # @private
    class NodeCollection
      ##
      # @private
      def initialize(incoming, klass, results, version)
        @klass = klass
        @incoming = incoming
        @results = results
        @version = version
      end

      ##
      # @private
      def permitted?(request, type)
        permissions(request).send("can_#{type}?")
      end

      def resource
        page = Onsi::Paginate.perform(@results, @klass.node_name, {})
        Onsi::Resource.as_resource(page, @version)
      end

      private

      def permissions(request)
        @klass.permissions.new(@incoming, request)
      end
    end
  end
end
