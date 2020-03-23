require File.expand_path('../boot', __FILE__)

require 'active_record/railtie'
require 'action_controller/railtie'

require_relative '../../../lib/onsi'

module Dummy
  class Application < Rails::Application
    config.middleware.use(Onsi::Middleware::CORSHeaders)

    if Rails::VERSION::MAJOR < 6 && config.active_record.sqlite3.respond_to?(:represent_boolean_as_integer=)
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end
  end
end
