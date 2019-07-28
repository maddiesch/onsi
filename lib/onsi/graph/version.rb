require_relative 'auto_loader'
require_relative 'traversal'

module Onsi
  module Graph
    class Version
      ##
      # @private
      VERSION_NAME_REGEXP = Regexp.new('\A(\d{4})-([01]\d)-([0-3]\d)\z').freeze

      attr_reader :root_node

      def initialize(version, root_class_name)
        raise 'Invalid Version String' unless VERSION_NAME_REGEXP.match?(version)

        @year, @month, @day = version.split('-', 3).map(&:to_i)
        @root_class_name = root_class_name
      end

      ##
      # @private
      class GraphVersion < Module
        attr_reader :instance

        def initialize(instance)
          super()
          @instance = instance
        end

        delegate :edges, :actions, :nodes, :root_node, :path, to: :instance
      end

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

      def edges
        @edges ||= load_edges
      end

      def nodes
        @nodes ||= load_nodes
      end

      def route(path)
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
