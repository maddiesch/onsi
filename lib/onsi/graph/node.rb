require 'active_support'

require_relative '../params'

require_relative 'error'
require_relative 'node_dsl'
require_relative 'abort'

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

        ##
        # @private
        def build_model(relationship, request)
          if (fn = builder).present?
            instance_exec(request, relationship, &fn)
          else
            relationship.new
          end
        end
      end

      define_callbacks :save, :create, :update, :destroy

      attr_reader :model

      attr_reader :version

      ##
      # @private
      def initialize(incoming, model, version)
        @incoming = incoming
        @model = model
        @version = version

        unless @model.present?
          raise Onsi::Graph::Abort.new(404, {}, nil)
        end

        unless @model.is_a?(self.class.model)
          raise Onsi::Graph::Abort.new(500, {}, nil)
        end
      end

      ##
      # @private
      def resource
        Onsi::Resource.as_resource(model, version)
      end

      ##
      # @private
      def permitted?(request, type)
        permissions(request).send("can_#{type}?")
      end

      ##
      # @private
      def create!(request)
        ActiveSupport::Notifications.instrument('onsi.graph.node-create', node: self) do
          run_callbacks :create do
            _create(request)
          end
        end
      end

      ##
      # @private
      def update!(request)
        ActiveSupport::Notifications.instrument('onsi.graph.node-update', node: self) do
          run_callbacks :update do
            _update(request)
          end
        end
      end

      ##
      # @private
      def destroy!(request)
        ActiveSupport::Notifications.instrument('onsi.graph.node-destroy', node: self) do
          run_callbacks :destroy do
            _destroy(request)
          end
        end
      end

      def assign_attributes(params)
        model.assign_attributes(params.flatten)
      end

      private

      def permissions(request)
        self.class.permissions.new(@incoming, request)
      end

      def _create(request)
        request.body.rewind
        params = Onsi::Params.parse_json(request.body.read, self.class.assign_create_attr, [])
        assign_attributes(params)
        _save!
      end

      def _update(request)
        request.body.rewind
        params = Onsi::Params.parse_json(request.body.read, self.class.assign_update_attr, [])
        assign_attributes(params)
        _save!
      end

      def _destroy(_request)
        model.destroy!
      end

      def _save!
        ActiveSupport::Notifications.instrument('onsi.graph.node-save', node: self) do
          run_callbacks :save do
            model.save!
          end
        end
      end
    end
  end
end
