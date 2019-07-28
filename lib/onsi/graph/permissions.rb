module Onsi
  module Graph
    ##
    # Permissions define the access model for graph nodes.
    #
    # @author Maddie Schipper
    # @since 2.0.0
    class Permissions
      class << self
        ##
        # @private
        def from(_version, permissions)
          if permissions.is_a?(Symbol)
            load_permissions(permissions)
          elsif permissions <= Onsi::Graph::Permissions
            permissions
          else
            raise 'unexpected permissions type'
          end
        end

        ##
        # Adding a named permission allows you to use the named dsl in models +permissions :custom+
        #
        # @param name [#to_sym] The name of the permission
        # @param klass [Class] A {Onsi::Graph::Permissions} subclass
        #
        # @return [void]
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

      ##
      # @private
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

      ##
      # Read only permissions are a default named permission.
      #
      # They allow any one to read but perform no other action.
      #
      # @example Setting read only
      #   permissions :read_only
      #
      # @author Maddie Schipper
      # @since 2.0.0
      class ReadOnly < Permissions
        ##
        # @return [true]
        def can_read?
          true
        end
      end
    end
  end
end
