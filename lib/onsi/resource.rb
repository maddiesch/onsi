module Onsi
  ##
  # The wrapper for generating a object
  #
  # @author Maddie Schipper
  # @since 1.0.0
  class Resource
    attr_reader :object
    attr_reader :version
    attr_reader :includes

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

    class InvalidResourceError < StandardError; end

    class << self
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

      def all_included(resources)
        Array(resources).map(&:flat_includes).flatten.uniq do |res|
          "#{res[TYPE_KEY]}-#{res[ID_KEY]}"
        end
      end
    end

    def initialize(object, version = nil, includes: nil)
      @object  = object
      @version = version || Model::DEFAULT_API_VERSION
      @includes = includes
      validate!
    end

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

    def rendered_includes
      @rendered_includes ||= perform_render_includes
    end

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
