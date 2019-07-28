require 'active_support'

require_relative 'response'

module Onsi
  module Graph
    ##
    # A model is the root of a graph. It contains all the details about the graph and it's versions.
    #
    # @example A simple model
    #   class AppGraph < Onsi::Graph::Model
    #     add_version(Onsi::Graph::Version.new('2019-07-01', 'Person'))
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
        # @example Add a version
        #   add_version(Onsi::Graph::Version.new('2019-07-01', 'Person'))
        #
        # @param version [Onsi::Graph::Version] The version to add.
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
        run_callbacks(:action) do
          _process
        end
      end

      private

      def _process
        @version = versions.detect { |v| v.to_s == request.version_name }
        _abort_unknown_version if @version.nil?

        @traversal = version.route(request.path)
        _abort_unknown_path if @traversal.nil?

        run_callbacks(:process) do
          _process_action
        end
      end

      def _process_action
        binding.pry
        true
      end

      def _response_unknown_version
        raise Onsi::Graph::Abort.new(404, _default_headers, nil)
      end

      def _abort_unknown_path
        raise Onsi::Graph::Abort.new(404, _default_headers, nil)
      end

      def _default_headers
        {
          'Content-Type' => 'application/json'
        }
      end
    end
  end
end
