module Onsi
  ##
  # Used to handle parsing JSON-API formated params
  class Params
    ##
    # Raised when a safe_fetch fails.
    #
    # @note The ErrorResponder will rescue from this and return an appropriate
    #   error to the user
    class RelationshipNotFound < StandardError
      ##
      # The key that the relationship wasn't found for
      #
      # @return [String]
      attr_reader :key

      ##
      # @private
      def initialize(message, key)
        super(message)
        @key = key.to_s
      end
    end

    ##
    # Raised when a required attribute has a nil value. `Params#require`
    #
    # @note The ErrorResponder will rescue from this and return an appropriate
    #   error to the user
    class MissingReqiredAttribute < StandardError
      ##
      # The attribute that was missing when required.
      #
      # @return [String]
      attr_reader :attribute

      ##
      # @private
      def initialize(message, attr)
        super(message)
        @attribute = attr.to_s
      end
    end

    class << self
      ##
      # Parse a JSON-API formatted params object.
      #
      # @param params [ActionController::Parameters] The parameters to parse.
      #
      # @param attributes [Array<String, Symbol>] The whitelisted attributes.
      #
      # @param relationships [Array<String, Symbol>] The whitelisted relationships.
      #   Should be the key for the relationships name.
      #
      # @return [Params] The new params object.
      def parse(params, attributes = [], relationships = [])
        data = params.require(:data)
        data.require(:type)
        attrs = permit_attributes(data, attributes)
        relas = permit_relationships(data, relationships)
        new(attrs, relas)
      end

      ##
      # Parse a JSON-API formatted JSON object.
      #
      # @param params [String, #read] The parameters to parse.
      #
      # @param attributes [Array<String, Symbol>] The whitelisted attributes.
      #
      # @param relationships [Array<String, Symbol>] The whitelisted relationships.
      #   Should be the key for the relationships name.
      #
      # @return [Params] The new params object.
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
            optional, true_name = parse_relationship_name(name)
            next unless rels.key?(true_name)

            resource = fetch_relationship(rels, optional, true_name)
            case resource
            when nil
              obj["#{true_name}_id".to_sym] = nil
            when Array
              ids = resource.map { |r| parse_relationship(r).last }
              obj["#{true_name.to_s.singularize}_ids".to_sym] = ids
            else
              _type, id = parse_relationship(resource)
              obj["#{true_name}_id".to_sym] = id
            end
          end
        end
      end

      def fetch_relationship(rels, optional, name)
        if optional
          payload = rels.require(name).permit!.to_h
          if payload[:data].is_a?(Array)
            return []
          end

          nil
        else
          rels.require(name).require(:data)
        end
      end

      def parse_relationship_name(name)
        name = name.to_s
        [name.start_with?('?'), name.gsub(/\A\?/, '')]
      end

      def parse_relationship(data)
        [
          data.require(:type),
          data.require(:id)
        ]
      end
    end

    ##
    # The attributes for the params.
    #
    # @return [ActionController::Parameters]
    attr_reader :attributes

    ##
    # The relationships for the params.
    #
    # @return [Hash]
    attr_reader :relationships

    ##
    # Create a new Params instance.
    #
    # @param attributes [ActionController::Parameters] The attributes
    #
    # @param relationships [Hash] Flattened relationships hash
    #
    # @note Should not be created directly. Use .parse or .parse_json
    #
    # @private
    def initialize(attributes, relationships)
      @attributes = attributes
      @relationships = relationships
    end

    ##
    # Flatten an merge the attributes & relationships into one hash.
    #
    # @return [Hash] The flattened attributes and relationships
    def flatten
      attrs_hash.to_h.merge(relationships.to_h).with_indifferent_access
    end

    ##
    # Fetch a value from the attributes or return the passed default value
    #
    # @param key [String, Symbol] The key to fetch.
    #
    # @param default [Any] The default value if the attribute doesn't exist.
    #
    # @return [Any]
    def fetch(key, default = nil)
      attrs_hash[key] || default
    end

    ##
    # Make an attributes key required.
    #
    # @param key [String, Symbol] The key of the attribute to require.
    #
    # @raise [MissingReqiredAttribute] The value you have required isn't present
    #
    # @return [Any] The value for the attribute
    def require(key)
      value = attrs_hash[key]
      if value.nil?
        raise MissingReqiredAttribute.new("Missing attribute #{key}", key)
      end

      value
    end

    ##
    # Handle finding a relationship's object.
    #
    # @param key [String, Symbol] The key for the relationship
    #
    # @raise [RelationshipNotFound] Thrown instead of an `ActiveRecord::RecordNotFound`
    #   This allows the `Onsi::ErrorResponder` to build an appropriate response.
    #
    # @example
    #   params.safe_fetch(:person) do |id|
    #     Person.find(id)
    #   end
    #
    # @return [Any]
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
    # @param key [String, Symbol] The key to transform.
    #
    # @param block [Block] The block to perform the transform.
    #
    # @note The values are memoized
    #
    # @example
    #   params.transform(:date) { |date| Time.parse(date) }
    #
    # @return [Any]
    def transform(key, &block)
      @attrs_hash = nil
      transforms[key.to_sym] = block
    end

    ##
    # Set a default value for attributes.
    #
    # This value will only be used if the key is missing from the passed attributes
    #
    # @param key [String, Symbol] The key to set a default on.
    #
    # @param value [Any, #call] The default value.
    #   If the object responds to call (Lambda) it will be called when
    #   parsing attributes
    #
    # @example
    #   params.default(:missing, -> { :foo })
    #   subject.flatten[:missing]
    #   # => :foo
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
