require 'active_support/callbacks'
require 'active_support/notifications'

require_relative 'response'
require_relative 'permissions'
require_relative '../resource'

module Onsi
  module Graph
    ##
    # A model is the root of a graph. It contains all the details about the graph and it's versions.
    #
    # @example A simple model
    #   class AppGraph < Onsi::Graph::Model
    #     add_version(Onsi::Graph::Version.new('2019-07-01', Onsi::Graph::Version::Root.new('Person', -> { Person.current })))
    #
    #     set_callback(:action, :before) do
    #       puts 'Callback Before Action'
    #       puts request.inspect
    #     end
    #
    #     set_callback(:action, :after) do
    #       puts 'Callback After Action'
    #     end
    #   end
    #
    # @author Maddie Schipper
    # @since 2.0.0
    class Model
      include ActiveSupport::Callbacks

      class << self
        ##
        # @private
        def versions
          @versions ||= []
          @versions
        end

        ##
        # Used to define a new version for the graph
        #
        # @param version [Onsi::Graph::Version] The version to add.
        #
        # @return [void]
        def add_version(version)
          version.load_version!(self)
          versions << version
        end

        ##
        # @private
        def [](year, month, day)
          format("#{name}::V%04i_%02i_%02i", year, month, day).constantize
        end

        ##
        # @private
        def paths
          @paths = versions.each_with_object({}) do |version, paths|
            paths[version.to_s] = []
            connected_edges = Set.new
            connected_nodes = Set.new([version.root_node])
            version.root_node.outbound_edges.each do |edge|
              paths[version.to_s] += walk_edge(edge, Pathname.new('/'), connected_edges, connected_nodes, Set.new)
            end
            paths[version.to_s].sort!
          end
        end

        private

        def walk_edge(edge, root, connected_edges, connected_nodes, current_edges)
          if current_edges.include?(edge)
            raise 'circular dependency detected?'
          end

          connected_edges.add(edge)
          current_edges.add(edge)

          paths = []
          root = root.join(edge.fragment)
          paths << root.to_s
          root = root.join(":#{edge.head.node_name}_id")
          paths << root.to_s
          connected_nodes.add(edge.head)
          edge.head.outbound_edges.each do |outbound|
            paths += walk_edge(outbound, root, connected_edges, connected_nodes, current_edges.dup)
          end

          paths
        end
      end

      define_callbacks :action, :process

      delegate :versions, :paths, to: :class

      ##
      # The current request being processed by the graph
      #
      # @return [Rack::Request]
      attr_reader :request

      ##
      # The version being used to process the request
      #
      # @return [Onsi::Graph::Version]
      attr_reader :version

      ##
      # The traversal for the current request
      #
      # @return [Array<Onsi::Graph::Traversal>]
      attr_reader :traversal

      attr_reader :response

      ##
      # @private
      def initialize(request)
        @request = request
        @response = Onsi::Graph::Response.new(204, _default_headers, nil)
      end

      ##
      # @private
      def call
        ActiveSupport::Notifications.instrument('onsi.graph.model-process') do
          run_callbacks(:action) do
            _process
          end
        end
      end

      private

      def _process
        @version = versions.detect { |v| v.to_s == request.version_name }
        _abort_unknown_version if @version.nil?

        @traversal = version.route(request.path)
        _abort_unknown_path if @traversal.nil?

        path_components = @traversal.each_with_object([]) do |trans, components|
          components << trans.edge.fragment if trans.edge.present?
          components << '*' if trans.id.present?
        end

        extra = {
          version: @version,
          traversal: @traversal,
          path: Pathname.new('/').join(*path_components).to_s
        }

        ActiveSupport::Notifications.instrument('onsi.graph.model-action', extra) do
          run_callbacks(:process) do
            _process_action
          end
        end
      end

      def _process_action
        root_instance = version.root_node_instance(request)
        working_traversal = traversal.dup
        instance = root_instance

        while (trans = working_traversal.shift).present?
          _abort_permissons_read_error unless instance.permitted?(request, :read)

          break if trans.edge.nil? # the root node

          edge = trans.edge.new(instance, trans.id)

          _abort_missing_path_component if edge.head.is_a?(Onsi::Graph::NodeCollection) && working_traversal.any?

          instance = edge.head
        end

        ActiveSupport::Notifications.instrument('onsi.graph.node-process', node: instance) do
          _process_node(instance)
        end
      end

      def _process_node(node)
        _abort_permissons_read_error unless node.permitted?(request, :read)

        case request.request_method
        when Rack::GET
          response.status = 200
          _render_node(node)
        when Rack::POST
        when Rack::PATCH
        when Rack::DELETE
        else
          _abort_bad_http_method
        end
        true
      end

      def _render_node(node)
        ActiveSupport::Notifications.instrument('onsi.graph.node-render', node: node) do
          resource = node.resource
          if resource.nil?
            response.body = nil
            response.status = 204
          else
            response.body = JSON.dump(Onsi::Resource.render(resource, version.render_version))
          end
        end
      end

      def _response_unknown_version
        raise Onsi::Graph::Abort.new(404, _default_headers, nil)
      end

      def _abort_unknown_path
        raise Onsi::Graph::Abort.new(404, _default_headers, nil)
      end

      def _abort_invalid_traversal
        raise Onsi::Graph::Abort.new(500, _default_headers, nil)
      end

      def _abort_permissons_read_error
        raise Onsi::Graph::Abort.new(401, _default_headers, nil)
      end

      def _abort_missing_path_component
        raise Onsi::Graph::Abort.new(400, _default_headers, nil)
      end

      def _abort_bad_http_method
        raise Onsi::Graph::Abort.new(400, _default_headers, nil)
      end

      def _default_headers
        {
          'Content-Type' => 'application/json'
        }
      end
    end
  end
end
