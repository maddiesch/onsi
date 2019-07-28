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

        private

        def default_fragment
          name.split('::').last.underscore.gsub(/\A#{tail.node_name}_/, '')
        end
      end
    end
  end
end
