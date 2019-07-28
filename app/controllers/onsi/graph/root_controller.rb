module Onsi
  module Graph
    class RootController < ActionController::Metal
      # include Onsi::ErrorResponder

      def root
        raise 'wip'
      end

      def graph_action
        par = ActionController::Parameters.new(params)
        req = Onsi::Graph::Request.new(request.env)
        req.env['onsi.graph.original_params'] = par
        req.env[Onsi::Graph::Request::ENV_VERSION_NAME] = par.require(:version)

        model = par.require(:model).new(req)
        model.call

        model.response.headers.each do |k, v|
          headers[k] = v
        end
        self.status = model.response.status
        self.response_body = model.response.body
      rescue Onsi::Graph::Abort => e
        e.headers.each do |k, v|
          headers[k] = v
        end
        self.status = e.status
        self.response_body = e.body
      end
    end
  end
end
