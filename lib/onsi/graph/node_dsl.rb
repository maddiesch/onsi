module Onsi
  module Graph
    ##
    # Syntax methods for a Node
    #
    # @author Maddie Schipper
    # @since 2.0.0
    module NodeDsl
      ##
      # Dsl methods for the Node class
      #
      # @author Maddie Schipper
      # @since 2.0.0
      module ClassMethods
        ##
        # Allows you to set the model that backs this node.
        #
        # @param model [Class] The model class
        #
        # @return [Class] The model backing the class
        def model(model = nil)
          @model = model unless model.nil?
          @model
        end

        ##
        # Add an attribute to the node.
        #
        # @param attr [Onsi::Graph::Attribute, #to_s] The attribute to be added.
        #
        #   Passing in a non {Onsi::Graph::Attribute} will attempt to create one using metadata found
        #   on the {.model} value.
        def attribute(attr)
          attributes << attr
        end
      end
    end
  end
end
