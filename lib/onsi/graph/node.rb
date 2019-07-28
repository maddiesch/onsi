require 'active_support'

require_relative 'error'
require_relative 'node_dsl'

module Onsi
  module Graph
    ##
    # A node is a point on the graph. Often referred to as a vertex.
    #
    # From a high level abstraction nodes represent a model in the database.
    #
    # @example A simple node
    #   class AppGraph[2019, 7, 1]::Nodes::Person < Onsi::Graph::Node
    #     model ::Person
    #
    #     attribute :name
    #   end
    #
    # @author Maddie Schipper
    # @since 2.0.0
    class Node
      include ActiveSupport::Callbacks
      include Onsi::Graph::NodeDsl

      extend Onsi::Graph::NodeDsl::ClassMethods

      class << self
        ##
        # @private
        def version_module
          @version_module ||= begin
            mod = parent.parent
            raise Onsi::Graph::ConfigurationError, 'Unexpected nesting for modules' unless mod.is_a?(Onsi::Graph::Version::GraphVersion)

            mod
          end
        end

        ##
        # @private
        def attributes
          @attributes ||= []
          @attributes
        end

        ##
        # @private
        def node_name
          name.split('::').last.underscore
        end

        ##
        # @private
        def outbound_edges
          @outbound_edges ||= version_module.edges.select { |e| e.tail == self }
        end

        ##
        # @private
        def inbound_edges
          @inbound_edges ||= version_module.edges.select { |e| e.head == self }
        end
      end

      define_callbacks :save, :build, :update, :destroy
    end
  end
end
