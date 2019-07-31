require_relative 'node_collection'

module Onsi
  module Graph
    ##
    # An edge connects two nodes in the graph.
    #
    # @author Maddie Schipper
    # @since 2.0.0
    class Edge
      class << self
        ##
        # The tail is the node that is being entered from.
        #
        # @param node [Class] The tail node.
        #
        # @return [Class]
        def tail(node = nil)
          @tail = node unless node.nil?
          @tail
        end
        alias from tail

        ##
        # The tail is the node that is being traveled to.
        #
        # @param node [Class] The head node.
        #
        # @return [Class]
        def head(node = nil)
          @head = node unless node.nil?
          @head
        end
        alias to head

        ##
        # The fragment is the URL path component that will be used to represent
        # the relationship between the tail & head.
        #
        # If this is not manually set the name of the edge will be used by removing
        # the tail's name from the name. e.g. +PersonEmails+ becomes +emails+
        #
        # @param fragment [#to_s] The fragment for the edge.
        #
        # @return [String] The fragment
        def fragment(fragment = nil)
          @fragment = fragment.to_s unless fragment.nil?
          @fragment.presence || default_fragment
        end

        ##
        # The association is how the head's contents are created.
        #
        # @example Association with a symbol
        #   association :emails
        #
        # @example Association with a block
        #   association do
        #     tail.emails
        #   end
        #
        # @param association [Symbol, nil] The method name for the association.
        # @param block [#call] A block that can be used to create an association.
        #
        # @return [#reorder, #limit, #where, #last, #first]
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
