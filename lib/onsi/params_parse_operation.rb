require_relative 'errors'

module Onsi
  ##
  # @private
  #
  # Parse a root object.
  class ParamsParseOperation
    MULTI_SOURCE_PATH = '*'.freeze

    ##
    # @private
    Result = Struct.new(:id, :attributes, :relationships) do
      def flattened
        attributes.merge(relationships)
      end
    end

    attr_reader :data, :attributes, :relationships, :included, :results

    def initialize(data, attributes, relationships, included)
      @data = data
      data.require(:type)
      @attributes = Array(attributes).map(&:to_s)
      @relationships = Array(relationships)
      @included = included
      @results = Result.new(data.fetch(:id, 'ambiguous'), {}, {})
    end

    def perform
      parse_attributes!
      parse_relationships!
      results
    end

    private

    def parse_attributes!
      return if attributes.empty?

      attrs = data.require(:attributes).permit!
      permitted = attrs.to_h.select { |key, _| attributes.include?(key.to_s) }
      results.attributes.merge!(permitted)
    end

    def parse_relationships!
      return if relationships.empty?

      relationship_params = data.require(:relationships)

      relationships.each do |relationship_key|
        case relationship_key
        when String, Symbol
          parse_relationship(relationship_key, relationship_params)
        when Hash
          parse_included(relationship_key, relationship_params)
        else
          raise ArgumentError, "Unexpected type for relationship #{relationship_key}"
        end
      end
    end

    ############################################################################
    ### Parse Included Relationships
    ############################################################################

    def parse_included(relationship_key, relationship_params)
      relationship_key.each do |key, value|
        error_message = "Must specify an array of permitted values for relationship #{key}"
        raise ArgumentError, error_message unless value.is_a?(Array)

        parse_included_relationship(key, value, relationship_params)
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def parse_included_relationship(key, value, params)
      relationship = params.fetch(key.to_sym, nil)
      return if relationship.nil?

      included_path = relationship.require(:data).fetch(:source, nil)
      return if included_path.nil?

      root, type, id = included_path.split('/', 4).reject(&:empty?).map(&:presence)

      unless root.present?
        raise Onsi::Errors::IncludedParamError.new("Invalid Source: /#{root}", included_path)
      end

      unless root == 'included'
        raise Onsi::Errors::IncludedParamError.new("Invalid Source: /#{root} is not included", included_path)
      end

      included_objects = find_included(type, id)

      if included_objects.nil? || included_objects.empty?
        raise Onsi::Errors::IncludedParamError.new('Invalid Source: Unable to find included.', included_path)
      end

      if included_objects.count != 1 && id != MULTI_SOURCE_PATH
        raise Onsi::Errors::IncludedParamError.new("Invalid Source: Unable to disambiguate included. #{type}", included_path)
      end

      attributes = value.reject { |val| val.is_a?(Hash) }.map(&:to_s)
      relationships = value.select { |val| val.is_a?(Hash) }.map { |hash| hash[:relationships] }.flatten

      parsed_included = included_objects.map do |object|
        self.class.new(object, attributes, relationships, included).perform
      end

      results.relationships[type] = {}

      case id
      when nil
        results.relationships[type] = parsed_included.first.flattened
      when MULTI_SOURCE_PATH
        results.relationships[type] = {}
        parsed_included.each do |included|
          results.relationships[type][included.id] = included.flattened
        end
      else
        results.relationships[type] = parsed_included.first.flattened
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

    def find_included(type, id)
      included.select do |param|
        next false unless param.require(:type).to_sym == type.to_sym
        next true unless id.present?
        next true if id == MULTI_SOURCE_PATH

        param.require(:id) == id
      end
    end

    ############################################################################
    ### Parse Simple Relationships
    ############################################################################

    def parse_relationship(relationship_key, relationship_params)
      optional, name = parse_relationship_name(relationship_key)
      return unless relationship_params.key?(name)

      relationship_data = fetch_relationship(optional, name, relationship_params)

      case relationship_data
      when nil
        results.relationships["#{name}_id".to_sym] = nil
      when Array
        ids = relationship_data.map { |r| parse_relationship_data(r).last }
        results.relationships["#{name.to_s.singularize}_ids".to_sym] = ids
      else
        _type, id = parse_relationship_data(relationship_data)
        results.relationships["#{name}_id".to_sym] = id
      end
    end

    def parse_relationship_name(name)
      name = name.to_s
      [name.start_with?('?'), name.gsub(/\A\?/, '')]
    end

    def parse_relationship_data(data)
      [
        data.require(:type),
        data.require(:id)
      ]
    end

    def fetch_relationship(optional, name, relationships)
      if optional
        payload = relationships.require(name).permit!.to_h
        return [] if payload[:data].is_a?(Array)

        nil
      else
        relationships.require(name).require(:data)
      end
    end
  end
end
