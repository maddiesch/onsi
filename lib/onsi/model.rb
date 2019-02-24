require 'active_support/concern'

module Onsi
  ##
  # The Model helper for create a renderable helper.
  #
  # @author Maddie Schipper
  # @since 1.0.0
  #
  # @example
  #   class Person < ApplicationRecord
  #     include Onsi::Model
  #
  #     api_render(:v1) do
  #       # Passing the name of the attribute only will call that name as a method on
  #       # the instance of the method.
  #       attribute(:first_name)
  #       attribute(:last_name)
  #       # You can give attribute a block and it will be called on the object
  #       # instance. This lets you rename or compute attributes
  #       attribute(:full_name) { "#{first_name} #{last_name}" }
  #
  #       # Relationship requires a minimum of 2 parameters. The first is the name
  #       # of the relationship in the rendered JSON. The second is the type.
  #       # When fetching the value, Onsi will add `_id` and call that method on the
  #       # object instance. e.g. `team_id` in this case.
  #       relationship(:team, :team)
  #
  #       # Relationships can take a block that will be called on the object instance
  #       # and the return value will be used as the ID
  #       relationship(:primary_email, :email) { emails.where(primary: true).first.id }
  #     end
  #   end
  module Model
    extend ActiveSupport::Concern

    ##
    # The current default rendered API version.
    DEFAULT_API_VERSION = :v1

    ##
    # Defines class methods available on the class.
    module ClassMethods
      ##
      # Add a version to be rendered.
      #
      # @param version [Symbol] The version that will trigger this render block.
      #
      # @param block [Block] The block. Called on an instance
      #   of {Onsi::Model::ModelRenderer}
      def api_render(version, id: :id, &block)
        api_renderer(version, id).instance_exec(&block)
      end

      ##
      # Fetch the {Onsi::Model::ModelRenderer} for the version.
      #
      # @param version [Symbol] The version to fetch the renderer for.
      #
      # @param for_render [true, false] Specifies if the version should be
      #   required to exist. Should only ever be true when attempting to render
      #   the resource.
      #
      # @raise [Onsi::Errors::UnknownVersionError] If the version isn't defined
      #   and the for_render param is true.
      def api_renderer(version, id, for_render: false)
        @api_renderer ||= {}
        if for_render
          raise Errors::UnknownVersionError.new(self, version) if @api_renderer[version].nil?
        else
          @api_renderer[version] ||= ModelRenderer.new(id)
        end
        @api_renderer[version]
      end
    end

    ##
    # The class that holds attributes and relationships for a model's version.
    #
    # @note You shouldn't ever have to directly interact with one of
    #   these classes.
    #
    # @author Maddie Schipper
    # @since 1.0.0
    class ModelRenderer
      ##
      # The default date format for a rendered Date. (ISO-8601)
      DATE_FORMAT = '%Y-%m-%d'.freeze

      ##
      # The default date-time format for a rendered Date and Time. (ISO-8601)
      DATETIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ'.freeze

      ##
      # The name of the id attribute on the model
      attr_reader :id_attr

      ##
      # Create a new ModelRenderer
      #
      # @private
      def initialize(id_attr)
        @id_attr = id_attr
        @attributes = {}
        @relationships = {}
        @metadata = {}
      end

      ##
      # The type name.
      #
      # @param name [String, nil] The resource object type name.
      #
      # @note Not required. If there is no type, the class name will be used
      #   when rendering the object. (Name is underscored)
      def type(name = nil)
        @type = name if name
        @type
      end

      ##
      # Add an attribute to the rendered attributes.
      #
      # @param name [String, Symbol, #to_sym] The name of the attribute.
      #   If no block is passed the name will be called on
      #   the {Onsi::Resource#object}
      #
      # @param block [Block] The block used to fetch a dynamic attribute.
      #   It will be executed in the context of the {Onsi::Resource#object}
      #
      # @example
      #   api_render(:v1) do
      #     attribute(:first_name)
      #     attribute(:last_name)
      #     attribute(:full_name) { "#{first_name} #{last_name}" }
      #
      #     # ...
      #
      #   end
      def attribute(name, &block)
        @attributes[name.to_sym] = block || name
      end

      ##
      # Add a relationship to the rendered relationships.
      #
      # @param name [Symbol, #to_sym] The relationship name.
      #
      # @param type [String, #to_s] The relationship type.
      #
      # @param block [Block] The block used to fetch a dynamic attribute.
      #   It will be executed in the context of the {Onsi::Resource#object}
      #
      # @example
      #   api_render(:v1) do
      #     relationship(:team, :team)
      #
      #     # ...
      #
      #   end
      def relationship(name, type, &block)
        @relationships[name.to_sym] = { type: type, attr: block || name }
      end

      ##
      # Add a metadata value to the rendered object's meta.
      #
      # @param name [#to_sym] The name for the meta value.
      #
      # @param block [Block] The block used to fetch the meta value.
      #   It will be executed in the context of the {Onsi::Resource#object}
      def meta(name, &block)
        @metadata[name.to_sym] = block
      end

      ##
      # Render all attributes
      #
      # @private
      def render_attributes(object)
        @attributes.each_with_object({}) do |(key, value), attrs|
          val = value.respond_to?(:call) ? object.instance_exec(&value) : object.send(value)
          attrs[key.to_s] = format_attribute(val)
        end
      end

      ##
      # Render all relationships
      #
      # @private
      def render_relationships(object)
        @relationships.each_with_object({}) do |(key, value), rels|
          render_relationship_entry(object, key, value, rels)
        end
      end

      ##
      # Render all metadata
      #
      # @private
      def render_metadata(object)
        @metadata.each_with_object({}) do |(key, block), meta|
          meta[key.to_s] = object.instance_exec(&block)
        end
      end

      private

      def render_relationship_entry(object, key, value, rels)
        attr = value[:attr]
        relationship = get_relationship_value(attr, object)
        data = format_relationship(relationship, value)
        rels[key.to_s] = {
          'data' => data
        }
      end

      def get_relationship_value(attr, object)
        if attr.respond_to?(:call)
          object.instance_exec(&attr)
        else
          object.send("#{attr}_id")
        end
      end

      def format_relationship(relationship, value)
        case relationship
        when Array
          relationship.map { |v| { 'type' => value[:type].to_s, 'id' => v.to_s } }
        else
          {
            'type' => value[:type].to_s,
            'id' => relationship.to_s
          }
        end
      end

      def format_attribute(value)
        case value
        when Date
          value.strftime(DATE_FORMAT)
        when DateTime, Time
          value.utc.strftime(DATETIME_FORMAT)
        when String
          value.presence
        else
          value
        end
      end
    end
  end
end
