module Onsi
  class Resource
    attr_reader :object, :version

    def initialize(object, version = Model::DEFAULT_API_VERSION)
      @object  = object
      @version = version
    end

    def as_json(_opts = {})
      {}.tap do |root|
        root['type'] = type
        root['id']   = object.id.to_s
        root['attributes'] = generate_attributes
        rela = generate_relationships
        root['relationships'] = rela if rela.any?
        meta = generate_metadata
        root['meta'] = meta if meta.any?
      end
    end

    private

    def type
      object.class.api_renderer(version, for_render: true).type || object.class.name.underscore
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
  end
end
