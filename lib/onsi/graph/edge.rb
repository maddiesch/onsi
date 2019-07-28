require_relative 'node_collection'

module Onsi
  module Graph
    class Edge
      class << self
        def tail(node = nil)
          @tail = node unless node.nil?
          @tail
        end
        alias from tail

        def head(node = nil)
          @head = node unless node.nil?
          @head
        end
        alias to head

        def fragment(fragment = nil)
          @fragment = fragment unless fragment.nil?
          @fragment.presence || default_fragment
        end

        def association(association = nil, &block)
          @association = association unless association.nil?
          @association = block if block_given?
          @association
        end

        private

        def default_fragment
          name.split('::').last.underscore.gsub(/\A#{tail.node_name}_/, '')
        end
      end

      attr_reader :tail

      ##
      # @private
      def initialize(tail, head_id)
        @tail = tail
        @head_id = head_id
      end

      ##
      # @private
      def head
        @head ||= load_head
      end

      private

      def call_association
        association = self.class.association
        if association.is_a?(Symbol)
          tail.model.send(association)
        elsif association.respond_to?(:call)
          instance_exec(&association)
        else
          raise 'unknown association type'
        end
      end

      def load_head
        instance = call_association
        if @head_id.present?
          self.class.head.new(self, instance.find(@head_id), tail.version)
        elsif instance.is_a?(Enumerable)
          Onsi::Graph::NodeCollection.new(self, self.class.head, instance, tail.version)
        elsif instance.is_a?(head.model)
          self.class.head.new(self, instance, tail.version)
        else
          raise 'unknown association value'
        end
      end
    end
  end
end
