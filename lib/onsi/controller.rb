require 'active_support/concern'

module Onsi
  ##
  # Helper methods for rendering API responses.
  #
  # @example
  #   class PersonController < ActionController::API
  #     include Onsi::Controller
  #
  #     render_version(:v1)
  #
  #     def show
  #       person = Person.find(params[:id])
  #       render_resource(person)
  #     end
  #   end
  module Controller
    extend ActiveSupport::Concern

    ##
    # Defines class methods available on the class.
    module ClassMethods
      ##
      # Set a controller wide default render version.
      #
      # @param version [Symbol] The version.
      def render_version(version = nil)
        @render_version = version if version
        @render_version
      end

      ##
      # Ensures that the render_version is set on a subclass
      #
      # @private
      def inherited(subclass)
        subclass.render_version(@render_version)
      end
    end

    ##
    # Render the JSON response.
    #
    # @param resource [Onsi::Resource, Enumerable, Onsi::Model]
    #
    # @param opts [Hash] The options hash. If a version is included that will
    #   take presidence over the controller default .render_version
    #
    #   - The other keys for opts will be passed directly the #render method.
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
