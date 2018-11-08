module Onsi
  ##
  # Used to handle parsing JSON-API formated params
  class Params
    ##
    # Raised when using `Params#safe_fetch`
    #
    # The ErrorResponder will rescue from this and return an appropriate
    # error to the user
    class RelationshipNotFound < StandardError
      attr_reader :key

      def initialize(message, key)
        super(message)
        @key = key
      end
    end

    ##
    # Raised when a required attribute has a nil value. `Params#require`
    #
    # The ErrorResponder will rescue from this and return an appropriate
    # error to the user
    class MissingReqiredAttribute < StandardError
      attr_reader :attribute

      def initialize(message, attr)
        super(message)
        @attribute = attr
      end
    end

    class << self
      def parse(params, attributes = [], relationships = [])
        data = params.require(:data)
        data.require(:type)
        attrs = permit_attributes(data, attributes)
        relas = permit_relationships(data, relationships)
        new(attrs, relas)
      end

      def parse_json(body, attributes = [], relationships = [])
        content = body.respond_to?(:read) ? body.read : body
        json = JSON.parse(content)
        params = ActionController::Parameters.new(json)
        parse(params, attributes, relationships)
      end

      private

      def permit_attributes(data, attributes)
        return {} if Array(attributes).empty?
        data.require(:attributes).permit(*attributes)
      end

      def permit_relationships(data, relationships)
        return {} if Array(relationships).empty?
        rels = data.require(:relationships)
        {}.tap do |obj|
          relationships.each do |name|
            next if rels[name].nil?
            resource = rels.require(name).require(:data)
            case resource
            when Array
              ids = resource.map { |r| parse_relationship(r).last }
              obj["#{name.to_s.singularize}_ids".to_sym] = ids
            else
              _type, id = parse_relationship(resource)
              obj["#{name}_id".to_sym] = id
            end
          end
        end
      end

      def parse_relationship(data)
        [
          data.require(:type),
          data.require(:id)
        ]
      end
    end

    attr_reader :attributes, :relationships

    def initialize(attributes, relationships)
      @attributes = attributes
      @relationships = relationships
    end

    ##
    # Flatten an merge the attributes & relationships into one hash.
    def flatten
      attrs_hash.to_h.merge(relationships.to_h).with_indifferent_access
    end

    ##
    # Fetch a value from the attributes or return the passed default value
    def fetch(key, default = nil)
      attrs_hash[key] || default
    end

    ##
    # Make an attributes key required.
    #
    # Throws MissingReqiredAttribute if the value is nil
    def require(key)
      value = attrs_hash[key]
      if value.nil?
        raise MissingReqiredAttribute.new("Missing attribute #{key}", key)
      end
      value
    end

    ##
    # Handle finding a relationship's object
    #
    # If an ActiveRecord::RecordNotFound is raised, a RelationshipNotFound error will
    # be raised so the ErrorResponder can build an appropriate error message
    #
    # params.safe_fetch(:person) do |id|
    #   Person.find(id)
    # end
    def safe_fetch(key)
      yield(@relationships[key])
    rescue ActiveRecord::RecordNotFound
      raise RelationshipNotFound.new("Can't find relationship #{key}", key)
    end

    ##
    # Perform a transform on the value
    #
    # Any getter will run the value through the transform block.
    #
    # (The values are memoized)
    #
    # `params.transform(:date) { |date| Time.parse(date) }`
    def transform(key, &block)
      @attrs_hash = nil
      transforms[key.to_sym] = block
    end

    ##
    # Set a default value.
    #
    # This value will only be used if the key is missing from the passed attributes
    #
    # Can take any object. If the object responds to call (Lambda) it will be called when
    # parsing attributes
    def default(key, value)
      @attrs_hash = nil
      defaults[key.to_sym] = value
    end

    private

    def transforms
      @transforms ||= {}
    end

    def defaults
      @defaults ||= {}
    end

    def attrs_hash
      @attrs_hash ||= transform_attributes.merge(default_attributes).with_indifferent_access
    end

    def transform_attributes
      attributes.to_h.each_with_object({}) do |(key, value), object|
        transform = transforms[key.to_sym]
        if transform
          object[key] = transform.call(value)
        else
          object[key] = value
        end
      end
    end

    def default_attributes
      raw_attrs = attributes.to_h.symbolize_keys
      defaults.each_with_object({}) do |(key, value), object|
        next if raw_attrs.key?(key)
        if value.respond_to?(:call)
          object[key] = value.call
        else
          object[key] = value
        end
      end
    end
  end
end
