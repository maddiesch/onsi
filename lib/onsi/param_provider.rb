require_relative 'params'

module Onsi
  ##
  # ParamProvider defines an interface that allows a class to provide it's own parameters
  #
  # @author Maddie Schipper
  # @since 2.0.0
  module ParamProvider
    ##
    # @private
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def assignable(attr)
        assignable_on_update(attr)
        assignable_on_create(attr)
      end

      def assignable_on_create(attr = nil)
        @assignable_on_create ||= Set.new
        @assignable_on_create.add(attr.to_s) unless attr.nil?
        @assignable_on_create
      end

      def assignable_on_update(attr = nil)
        @assignable_on_update ||= Set.new
        @assignable_on_update.add(attr.to_s) unless attr.nil?
        @assignable_on_update
      end

      def parameters(data, target)
        Onsi::Params.parse(data, send("assignable_on_#{target}").to_a, [])
      end
    end
  end
end
