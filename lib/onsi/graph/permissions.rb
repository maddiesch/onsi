module Onsi
  module Graph
    class Permissions
      class << self
        def from(_version, permissions)
          if permissions.is_a?(Symbol)
            load_permissions(permissions)
          elsif permissions <= Onsi::Graph::Permissions
            permissions
          else
            raise 'unexpected permissions type'
          end
        end

        def add_named_permissions(name, klass)
          raise ArgumentError, 'Invalid permission type' unless klass <= Onsi::Graph::Permissions

          named_permissions[name.to_sym] = klass
        end

        private

        def named_permissions
          @named_permissions ||= {}
          @named_permissions
        end

        def load_permissions(permissions)
          case permissions
          when :read_only
            Onsi::Graph::Permissions::ReadOnly
          else
            raise "unknown permissions for name '#{permissions}'" unless named_permissions.key?(permissions)

            named_permissions[permissions]
          end
        end
      end

      attr_reader :tail

      attr_reader :request

      def initialize(tail, request)
        @tail = tail
        @request = request
      end

      def can_read?
        false
      end

      def can_create?
        false
      end

      def can_update?
        false
      end

      def can_destroy?
        can_update?
      end

      class ReadOnly < Permissions
        def can_read?
          true
        end
      end
    end
  end
end
