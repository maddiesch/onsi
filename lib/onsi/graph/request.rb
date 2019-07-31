module Onsi
  module Graph
    ##
    # @private
    class Request < ::Rack::Request
      ENV_VERSION_NAME = 'onsi.graph.version_name'.freeze

      def path
        path_info.gsub(%r{\A\/#{Regexp.escape(version_name)}}, '')
      end

      def version_name
        env[Onsi::Graph::Request::ENV_VERSION_NAME]
      end
    end
  end
end
