class PeopleController < ApplicationController
  include Onsi::Controller

  def index_v1
    render_resource Person.all, version: :v1
  end

  def index_v2
    render_resource Person.all, version: :v2
  end
end
