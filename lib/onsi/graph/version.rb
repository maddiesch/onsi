require_relative 'auto_loader'
require_relative 'traversal'

module Onsi
  module Graph
    ##
    # A Graph version
    #
    # A version encapsulates the edges and nodes for a specific version of the graph.
    #
    # @author Maddie Schipper
    # @since 2.0.0
    class Version
      ##
      # The root of a version.
      #
      # @!attribute [rw] name
      #   The root of the version.
      #
      #   @return [String]
      #
      # @!attribute [rw] fetcher
      #   Must return a single instance of the root node's model.
      #
      #   @return [#call]
      Root = Struct.new(:name, :fetcher)

      ##
      # @private
      VERSION_NAME_REGEXP = Regexp.new('\A(\d{4})-([01]\d)-([0-3]\d)\z').freeze

      ##
      # @private
      attr_reader :root_node

      ##
      # The default version used to render a node's resource
      #
      # @return [Symbol] The version e.g. +:v1+
      attr_reader :render_version

      ##
      # The fetcher is what is called to fetch the root resource for the root node
      attr_reader :fetcher

      ##
      # Create a new version of the graph.
      #
      # @example Creating a version
      #   Onsi::Graph::Version.new(
      #     '2019-07-01',
      #     Onsi::Graph::Version::Root.new('Person', ->(_) { Person.current }),
      #     render_version: :v2
      #   )
      #
      # @param version [String] The version number +2019-07-01+
      # @param root [String] The class name of the root node.
      # @param render_version [Symbol] The default render version.
      #
      # @return [void]
      def initialize(version, root, render_version: :v1)
        raise 'Invalid Version String' unless VERSION_NAME_REGEXP.match?(version)

        @year, @month, @day = version.split('-', 3).map(&:to_i)
        @root_class_name = root.name
        @fetcher = root.fetcher
        @render_version = render_version
      end

      ##
      # @private
      class GraphVersion < Module
        attr_reader :instance

        def initialize(instance)
          super()
          @instance = instance
        end

        delegate :edges, :actions, :nodes, :root_node, :path, :renderable, to: :instance
      end

      ##
      # Returns the string representation of the version.
      #
      # @return [String]
      def to_s
        format('%04i-%02i-%02i', @year, @month, @day)
      end

      ##
      # @private
      def module_name
        format('V%04i_%02i_%02i', @year, @month, @day)
      end

      ##
      # @private
      def version_module
        @model_klass.const_get(module_name)
      end

      ##
      # @private
      def root_node_instance(request)
        root_node.new(nil, fetcher.call(request), render_version)
      end

      ##
      # @private
      def load_version!(model_klass)
        @model_klass = model_klass
        @model_klass.const_set(module_name, GraphVersion.new(self))
        @root_node = "#{version_module.name}::Nodes::#{@root_class_name}".constantize

        # preload
        nodes
        edges

        true
      end

      ##
      # @private
      def path
        Rails.root.join('app/graphs', @model_klass.name.underscore, module_name.downcase)
      end

      ##
      # @private
      def edges
        @edges ||= load_edges
      end

      ##
      # @private
      def nodes
        @nodes ||= load_nodes
      end

      ##
      # @private
      def route(path)
        path = path.gsub(/\A#{Regexp.escape(File::SEPARATOR)}/, '')
        node = root_node
        parts = path.split(File::SEPARATOR)

        if parts.empty?
          return [
            Onsi::Graph::Traversal.new(nil, root_node, nil)
          ]
        end

        traversals = []

        while (fragment, id = parts.shift(2)).present?
          edge = node.outbound_edges.detect { |e| e.fragment == fragment }
          return nil if edge.nil?

          node = edge.head

          traversals << Onsi::Graph::Traversal.new(edge, edge.tail, id.presence)
        end

        traversals
      end

      private

      def load_nodes
        Dir[path.join('nodes/*')].map do |path|
          Graph::AutoLoader.auto_load(path, version_module)
        end
      end

      def load_edges
        Dir[path.join('edges/*')].map do |path|
          Graph::AutoLoader.auto_load(path, version_module)
        end
      end
    end
  end
end
