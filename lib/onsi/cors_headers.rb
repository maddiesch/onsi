require 'addressable'
require 'set'

module Onsi
  ##
  # Generates CORS Headers using a request env.
  #
  # @example Creating headers in a before_action
  #   def assign_cors_headers
  #     Onsi::CORSHeaders.generate(request.env) do |header, value|
  #       response.headers[header] = value
  #     end
  #   end
  class CORSHeaders
    ##
    # @private
    #
    # Default Allowed Headers
    CORS_ALLOWED_HEADER = %w[
      Accept
      Authorization
      Content-Type
      If-Match
      If-Modified-Since
      If-None-Match
      If-Unmodified-Since
      Origin
      X-Requested-With
      X-CSRF-Token
    ].freeze

    ##
    # @private
    #
    # Default Allowed Methods
    CORS_ALLOWED_METHOD = %w[
      GET POST PATCH PUT DELETE OPTIONS
    ].freeze

    ##
    # @private
    #
    # Default Expose Headers
    CORS_EXPOSE_HEADER = %w[
      ETag Link
    ].freeze

    ##
    # @private
    #
    # Default Known Origins
    CORS_KNOWN_ORIGIN = %w[
      localhost
    ].freeze

    ##
    # @private
    #
    # Default Vary
    CORS_VARY = %w[
      Accept Accept-Encoding Origin
    ].freeze

    ##
    # @private
    #
    # Values that can be customized
    CUSTOMIZED_VALUES = %w[
      allowed_header
      allowed_method
      expose_header
      known_origin
      vary
    ].freeze

    class << self
      ##
      # Create the CORS headers.
      #
      # @param env [Hash] The request env to generate CORS headers from.
      #
      # @return [Hash]
      def generate(env)
        new(env).generate
      end

      CUSTOMIZED_VALUES.each do |method|
        define_method("add_#{method}") do |origin|
          send("#{method}s").add(origin)
        end

        define_method("#{method}s") do
          variable_name = "@#{method}s"
          existing = instance_variable_get(variable_name)
          return existing unless existing.nil?

          default_values = Object.const_get("Onsi::CORSHeaders::CORS_#{method.upcase}")

          existing = Set.new(default_values)

          instance_variable_set(variable_name, existing)

          existing
        end
      end
    end

    ##
    # @private
    #
    # The request object.
    #
    # @return [Rack::Request]
    attr_reader :request

    ##
    # @private
    #
    # @param env [Hash] The request env for CORS Headers
    def initialize(env)
      @request = Rack::Request.new(env)
    end

    ##
    # @private
    #
    # Generates CORS headers
    def generate
      {}.tap do |headers|
        headers['Access-Control-Allow-Credentials'] = 'true'
        headers['Access-Control-Allow-Origin']      = allowed_origin if allowed_origin
        headers['Access-Control-Expose-Headers']    = self.class.expose_headers.to_a.join(', ')
        headers['Access-Control-Allow-Methods']     = self.class.allowed_methods.to_a.join(', ')
        headers['Vary']                             = self.class.varys.to_a.join(', ')
      end
    end

    private

    def origin_header
      (request.env['HTTP_ORIGIN'].presence || request.env['Origin'].presence).to_s
    end

    def origin
      @origin ||= Addressable::URI.parse(origin_header)
    rescue Addressable::URI::InvalidURIError
      Addressable::URI.new
    end

    def origin_value
      origin.to_s
    end

    def allowed_origin
      if acceptable_options_request?
        origin_value if request_from_known_origin?
      else
        '*'
      end
    end

    def acceptable_options_request?
      options_request? && request_from_known_origin?
    end

    def request_from_known_origin?
      self.class.known_origins.include?(origin.host)
    end

    def options_request?
      request.request_method == 'OPTIONS'
    end
  end
end
