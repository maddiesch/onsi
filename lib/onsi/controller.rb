require 'active_support/concern'

module Onsi
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def render_version(version = nil)
        @render_version = version if version
        @render_version
      end
    end

    def render_resource(resource, opts = {})
      version = opts.delete(:version) || self.class.render_version || Model::DEFAULT_API_VERSION
      payload = format_resource(resource, version)
      render_options = {}
      render_options[:json] = { data: payload }
      render_options.merge!(opts)
      render(render_options)
    end

    def format_resource(resource, version)
      case resource
      when Onsi::Resource
        resource
      when Enumerable
        resource.map { |res| format_resource(res, version) }
      else
        Onsi::Resource.new(resource, version)
      end
    end
  end
end
