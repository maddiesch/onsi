require_relative 'params_parse_operation'

module Onsi
  class ParamsParser
    attr_reader :data
    attr_reader :included
    attr_reader :attributes
    attr_reader :relationships

    def initialize(params, attributes, relationships)
      @data = params.require(:data)
      @included = params.fetch(:included, [])
      @attributes = attributes
      @relationships = relationships
    end

    def parse!
      operation = Onsi::ParamsParseOperation.new(data, attributes, relationships, included)
      operation.perform
    end
  end
end
