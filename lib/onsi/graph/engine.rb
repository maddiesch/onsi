module Onsi
  module Graph
    class Engine < ::Rails::Engine
      isolate_namespace Onsi

      config.autoload_paths << config.root.join('app/graphs')
    end
  end
end
