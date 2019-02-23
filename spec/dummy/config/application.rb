require File.expand_path('../boot', __FILE__)

require 'rails/all'

require_relative '../../../lib/onsi'

module Dummy
  class Application < Rails::Application
    config.active_record.sqlite3.represent_boolean_as_integer = true
    config.middleware.use(Onsi::Middleware::CORSHeaders)
  end
end
