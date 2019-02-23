class ApplicationController < ActionController::Base
  def cors_options
    head(:no_content)
  end
end
