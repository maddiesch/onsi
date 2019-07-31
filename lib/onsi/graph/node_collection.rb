require_relative '../resource'
require_relative '../paginate'

module Onsi
  module Graph
    ##
    # @private
    class NodeCollection
      ##
      # @private
      attr_reader :klass

      ##
      # @private
      attr_reader :incoming

      ##
      # @private
      attr_reader :results

      ##
      # @private
      attr_reader :version

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

      ##
      # @private
      def resource
        page = Onsi::Paginate.perform(results, klass.node_name, {})
        Onsi::Resource.as_resource(page, version)
      end

      ##
      # @private
      def create(request)
        model = klass.build_model(incoming.head.results, request)
        node = klass.new(incoming, model, version)
        node.create!(request)
        node
      end

      private

      def permissions(request)
        klass.permissions.new(incoming, request)
      end
    end
  end
end
