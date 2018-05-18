require 'active_support/concern'

module Onsi
  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def render_version(version = nil)
        @render_version = version if version
        @render_version
      end

      def inherited(subclass)
        subclass.render_version(@render_version)
      end
    end

    def render_resource(resource, opts = {})
      version = opts.delete(:version) || self.class.render_version || Model::DEFAULT_API_VERSION
      payload = Resource.render(resource, version)
      render_options = {}
      render_options[:json] = payload
      render_options.merge!(opts)
      render(render_options)
    end
  end
end
