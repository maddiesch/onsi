class PeopleController < ApplicationController
  include Onsi::Controller
  include Onsi::ErrorResponder

  def index
    render_resource Person.all, version: params[:version].to_sym
  end
end
