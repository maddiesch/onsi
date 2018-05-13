require 'active_support/concern'

module Onsi
  module Model
    DEFAULT_API_VERSION = :v1

    extend ActiveSupport::Concern

    module ClassMethods
      def api_render(version = DEFAULT_API_VERSION, &block)
        api_renderer(version).instance_exec(&block)
      end

      def api_renderer(version = DEFAULT_API_VERSION, for_render: false)
        @api_renderer ||= {}
        if for_render
          raise Errors::UnknownVersionError.new(self, version) if @api_renderer[version].nil?
        else
          @api_renderer[version] ||= ModelRenderer.new
        end
        @api_renderer[version]
      end

      class ModelRenderer
        DATE_FORMAT = '%Y-%m-%d'.freeze
        DATETIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ'.freeze

        def initialize
          @attributes = {}
          @relationships = {}
          @metadata = {}
        end

        def type(name = nil)
          @type = name if name
          @type
        end

        def attribute(name, &block)
          @attributes[name.to_sym] = block || name
        end

        def relationship(name, type, &block)
          @relationships[name.to_sym] = { type: type, attr: block || name }
        end

        def meta(name, &block)
          @metadata[name.to_sym] = block
        end

        def render_attributes(object)
          @attributes.each_with_object({}) do |(key, value), attrs|
            val = value.respond_to?(:call) ? object.instance_exec(&value) : object.send(value)
            attrs[key.to_s] = format_attribute(val)
          end
        end

        def render_relationships(object)
          @relationships.each_with_object({}) do |(key, value), rels|
            render_relationship_entry(object, key, value, rels)
          end
        end

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
end
