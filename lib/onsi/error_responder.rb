require 'active_support/concern'

module Onsi
  ##
  # Handles default errors without StandardError
  #
  # Error handled by default:
  # - ActiveRecord::RecordNotFound
  # - ActiveRecord::RecordInvalid
  # - ActionController::ParameterMissing
  # - {Onsi::Params::MissingReqiredAttribute}
  # - {Onsi::Params::RelationshipNotFound}
  # - {Onsi::Errors::UnknownVersionError}
  #
  # @example
  #   class PeopleController < ApplicationController
  #     include Onsi::Controller
  #     include Onsi::ErrorResponderBase
  #
  #     # ...
  #   end
  #
  # @author Maddie Schipper
  # @since 1.0.0
  module ErrorResponderBase
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound,          with: :render_error_404
      rescue_from ActiveRecord::RecordInvalid,           with: :render_error_422
      rescue_from ActionController::ParameterMissing,    with: :respond_param_error_400
      rescue_from Onsi::Params::MissingReqiredAttribute, with: :respond_missing_attr_error_400
      rescue_from Onsi::Params::RelationshipNotFound,    with: :respond_missing_relationship_error_400
      rescue_from Onsi::Errors::UnknownVersionError,     with: :respond_invalid_version_error_400
    end

    ##
    # Render an API error response.
    #
    # @param response [Onsi::ErrorResponse] The response object to render
    def render_error(response)
      render(response.renderable)
    end

    ##
    # Can be overriden to report an un-handled exception to your error service
    # of choice.
    #
    # @param exception [StandardError] The error to report.
    #
    # @example
    #   class ApplicationController < ActionController::API
    #     include Onsi::ErrorResponderBase
    #     include Onsi::Controller
    #
    #     def notify_unhandled_exception(exception)
    #       Bugsnag.notify(exception)
    #     end
    #
    #     # ...
    #   end
    def notify_unhandled_exception(exception)
      Rails.logger.error "Unhandled Exception `#{exception.class.name}: #{exception.message}`"
    end

    ##
    # @private
    def render_error_404(_error)
      response = ErrorResponse.new(404)
      response.add(404, 'not_found')
      render_error(response)
    end

    ##
    # @private
    def render_error_422(error)
      response = ErrorResponse.new(422)
      error.record.errors.details.each do |name, details|
        details.each do |info|
          response.add(
            422,
            'validation_error',
            title: "Validation Error: #{info[:error]}",
            meta: info.merge(param: name)
          )
        end
      end
      render_error(response)
    end

    ##
    # @private
    def respond_param_error_400(error)
      response = ErrorResponse.new(400)
      response.add(
        400,
        'missing_parameter',
        meta: { param: error.param }
      )
      render_error(response)
    end

    ##
    # @private
    def respond_missing_relationship_error_400(error)
      response = ErrorResponse.new(400)
      response.add(
        400,
        'missing_relationship',
        meta: { param: error.key }
      )
      render_error(response)
    end

    ##
    # @private
    def respond_invalid_version_error_400(error)
      notify_unhandled_exception(error)
      response = ErrorResponse.new(400)
      response.add(
        400,
        'invalid_version',
        details: "API version #{error.version} unsupported for #{error.klass.name.underscore}"
      )
      render_error(response)
    end

    ##
    # @private
    def respond_missing_attr_error_400(error)
      response = ErrorResponse.new(400)
      response.add(
        400,
        'missing_attribute',
        meta: {
          attribute: error.attribute
        }
      )
      render_error(response)
    end

    private

    def error_metadata(error)
      return nil unless Rails.configuration.consider_all_requests_local

      {
        exception: {
          '_note' => '`exception` will be removed if Rails.configuration.consider_all_requests_local is false',
          class: error.class.name,
          message: error.message,
          backtrace: error.backtrace
        }
      }
    end
  end

  ##
  # The error response container.
  #
  # @author Maddie Schipper
  # @since 1.0.0
  #
  # @example
  #   def handle_error(error)
  #     response = Onsi::ErrorResponse.new(400)
  #     response.add(400, 'bad_request', title: 'The payload was invalid')
  #     render_error(response)
  #   end
  class ErrorResponse
    ##
    # The HTTP status for the response.
    #
    # @return [Integer]
    attr_reader :status

    ##
    # Create a new ErrorResponse
    #
    # @param status [Integer] The HTTP status for the response.
    def initialize(status)
      @status = status
      @errors = []
    end

    ##
    # Add a renderable error to the errors
    #
    # @param status [#to_s, nil] The status of the error. Usually the same as
    #   the HTTP status passed to #initialize
    #
    # @param code [String] The error code for the error. e.g. `bad_request`
    #
    # @param title [String, nil] The user displayable title for the error.
    #
    # @param details [String, nil] The user displayable details for the error.
    #
    # @param meta [Hash, nil] Any additional metadata to associate
    #   with the error.
    def add(status, code, title: nil, details: nil, meta: nil)
      @errors << {}.tap do |err|
        err[:status] = (status || @status).to_s
        err[:code]   = code
        err[:title]  = title      if title.present?
        err[:detail] = details    if details.present?
        err[:meta]   = Hash(meta) if meta.present?
      end
    end

    ##
    # Create the error objects.
    #
    # @return [Hash] The JSON-API error hash.
    def as_json
      { errors: @errors.as_json }
    end

    ##
    # Returns a hash that can be passed to #render
    #
    # @private
    def renderable
      {
        json:   as_json,
        status: status
      }
    end
  end
end

module Onsi
  ##
  # Handles default errors and builds JSON-API responses.
  #
  # @note Also includes Onsi::ErrorResponderBase but will add a StandardError
  #   handler.
  #
  # @example
  #   class PeopleController < ApplicationController
  #     include Onsi::Controller
  #     include Onsi::ErrorResponder
  #
  #     # ...
  #   end
  module ErrorResponder
    extend ActiveSupport::Concern

    included do
      rescue_from StandardError, with: :render_error_500
      include(Onsi::ErrorResponderBase)
    end

    ##
    # Render a 500 error.
    #
    # @private
    def render_error_500(error)
      notify_unhandled_exception(error)
      response = ErrorResponse.new(500)
      response.add(500, 'internal_server_error', meta: error_metadata(error))
      render_error(response)
    end
  end
end
