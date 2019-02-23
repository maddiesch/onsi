require_relative '../cors_headers'

module Onsi
  module Middleware
    ##
    # Auto-Add CORS headers to all requests.
    #
    # @example Setup The middleware
    #   # in config/application.rb
    #   module CoolApp
    #     class Application < Rails::Application
    #       config.middleware.use(Onsi::Middleware::CORSHeaders)
    #     end
    #   end
    class CORSHeaders
      ##
      # @private
      #
      # Create a new instance of the middleware.
      #
      # @param app [] Rack App
      def initialize(app)
        @app = app
      end

      ##
      # @private
      #
      # Called by the Middleware stack.
      def call(env)
        status, headers, body = @app.call(env)

        cors_headers = Onsi::CORSHeaders.generate(env)

        [
          status,
          cors_headers.merge(headers),
          body
        ]
      end
    end
  end
end
