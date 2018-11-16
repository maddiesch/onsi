require_relative 'errors'

module Onsi
  ##
  # The wrapper for generating a object
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Resource
    ##
    # Root object type key
    #
    # @private
    TYPE_KEY = 'type'.freeze

    ##
    # Root object id key
    #
    # @private
    ID_KEY = 'id'.freeze

    ##
    # Root object attributes key
    #
    # @private
    ATTRIBUTES_KEY = 'attributes'.freeze

    ##
    # Root object relationships key
    #
    # @private
    RELATIONSHIPS_KEY = 'relationships'.freeze

    ##
    # Root object meta key
    #
    # @private
    META_KEY = 'meta'.freeze

    ##
    # Root object data key
    #
    # @private
    DATA_KEY = 'data'.freeze

    ##
    # Root object included key
    #
    # @private
    INCLUDED_KEY = 'included'.freeze

    ##
    # Raised if the resource or includes are invalid.
    class InvalidResourceError < Onsi::Errors::BaseError; end

    class << self
      ##
      # Convert an object into a Onsi::Resource
      #
      # @param resource [Onsi::Resource, Enumerable, ActiveRecord::Base] The
      #   object to be converted.
      #   - If a Onsi::Resource is passed it will be directly returned.
      #   - If an Enumerable is passed #map will be called and .as_resource will
      #     be recursivly called for each object.
      #   - If any other object is passed it will be wrapped in a Onsi::Resource
      #
      # @param version [Symbol] The version of the resource. `:v1`
      #
      # @return [Onsi::Resource, Array<Onsi::Resource>]
      def as_resource(resource, version)
        case resource
        when Onsi::Resource
          resource
        when Enumerable
          resource.map { |res| as_resource(res, version) }
        else
          Onsi::Resource.new(resource, version)
        end
      end

      ##
      # Render a resource to JSON
      #
      # @param resource (see .as_resource)
      #
      # @param version [Symbol] The version to render as. `:v1`
      #
      # @return [Hash] The rendered resource as a hash ready to be converted
      #   to JSON.
      def render(resource, version)
        resources = as_resource(resource, version)
        {}.tap do |root|
          root[DATA_KEY] = resources.as_json
          included = all_included(resources)
          if included.any?
            root[INCLUDED_KEY] = included
          end
        end
      end

      private

      def all_included(resources)
        Array(resources).map(&:flat_includes).flatten.uniq do |res|
          "#{res[TYPE_KEY]}-#{res[ID_KEY]}"
        end
      end
    end

    ##
    # The backing object.
    #
    # @note MUST include Onsi::Model
    #
    # @return [Any] The object to be rendered by the resource.
    attr_reader :object

    ##
    # The version to render.
    #
    # @return [Symbol]
    attr_reader :version

    ##
    # The includes for the object.
    #
    # @return [Array<Onsi::Includes>]
    attr_reader :includes

    ##
    # Create a new resouce.
    #
    # @param object [Any] The resource backing object.
    #
    # @param version [Symbol] The version to render. Can be nil. If nil is
    #   passed the DEFAULT_API_VERSION will be used.
    #
    # @note The object MUST be a single object that includes Onsi::Model
    #
    # @note The includes MUST be an array of Onsi::Include objects.
    #
    # @return [Onsi::Resource] The new resource
    def initialize(object, version = nil, includes: nil)
      @object  = object
      @version = version || Model::DEFAULT_API_VERSION
      @includes = includes
      validate!
    end

    ##
    # Creates a raw JSON object.
    #
    # @return [Hash]
    def as_json(_opts = {})
      {}.tap do |root|
        root[TYPE_KEY] = type
        root[ID_KEY]   = object.id.to_s
        root[ATTRIBUTES_KEY] = generate_attributes
        append_relationships(root)
        append_meta(root)
        append_includes(root)
      end
    end

    ##
    # All rendered includes
    #
    # @private
    def rendered_includes
      @rendered_includes ||= perform_render_includes
    end

    ##
    # Flat includes
    #
    # @private
    def flat_includes
      rendered_includes.values.map { |root| root[DATA_KEY] }.flatten
    end

    private

    def validate!
      unless object.class.included_modules.include?(Onsi::Model)
        raise InvalidResourceError, "Trying to render a #{object.class.name}. But it doesn't include Onsi::Model"
      end
      if includes.present? && !includes.is_a?(Onsi::Includes)
        raise InvalidResourceError, "Included resources in #{self} is not a Onsi::Includes"
      end
    end

    def type
      object.class.api_renderer(version, for_render: true).type || object.class.name.underscore
    end

    def append_relationships(root)
      relationships = generate_relationships
      return unless relationships.any?

      root[RELATIONSHIPS_KEY] = relationships
    end

    def append_meta(root)
      meta = generate_metadata
      return unless meta.any?

      root[META_KEY] = meta
    end

    def append_includes(root)
      includes = generate_includes
      return unless includes.any?

      root[RELATIONSHIPS_KEY] ||= {}
      root[RELATIONSHIPS_KEY].merge!(includes)
    end

    def generate_attributes
      object.class.api_renderer(version, for_render: true).render_attributes(object)
    end

    def generate_relationships
      object.class.api_renderer(version, for_render: true).render_relationships(object)
    end

    def generate_metadata
      object.class.api_renderer(version, for_render: true).render_metadata(object)
    end

    def generate_includes
      {}.tap do |root|
        rendered_includes.each do |key, values|
          included = values[DATA_KEY]
          case included
          when Array
            root[key] = {}.tap do |subobj|
              subobj[DATA_KEY] = included.map do |inc|
                {
                  TYPE_KEY => inc[TYPE_KEY],
                  ID_KEY   => inc[ID_KEY]
                }
              end
            end
          when Hash
            root[key] = { DATA_KEY => { TYPE_KEY => included[TYPE_KEY], ID_KEY => included[ID_KEY] } }
          end
        end
      end
    end

    def perform_render_includes
      included = includes&.load_included
      {}.tap do |root|
        Hash(included).each do |key, results|
          root[key.to_s] = {}
          root[key.to_s][DATA_KEY] = render_included(results)
        end
      end
    end

    def render_included(resources)
      Resource.as_resource(resources, version).as_json
    end
  end
end
