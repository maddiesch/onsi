module Onsi
  class Params
    class RelationshipNotFound < StandardError
      attr_reader :key

      def initialize(message, key)
        super(message)
        @key = key
      end
    end

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

    def flatten
      attributes.to_h.merge(relationships.to_h).with_indifferent_access
    end

    def fetch(key, default = nil)
      attrs_hash[key] || default
    end

    def require(key)
      value = attrs_hash[key]
      if value.nil?
        raise MissingReqiredAttribute.new("Missing attribute #{key}", key)
      end
      value
    end

    def safe_fetch(key)
      yield(@relationships[key])
    rescue ActiveRecord::RecordNotFound
      raise RelationshipNotFound.new("Can't find relationship #{key}", key)
    end

    private

    def attrs_hash
      @attrs_hash ||= attributes.to_h.with_indifferent_access
    end
  end
end
