class EmailsController < ApplicationController
  include Onsi::Controller

  def index_v1
    @person = Person.find(params[:person_id])
    render_resource @person.emails.to_a, version: :v1
  end

  def show_v1
    @person = Person.find(params[:person_id])
    render_resource Onsi::Resource.new(@person.emails.find(params[:id]), :v1)
  end

  def show_v2
    @person = Person.find(params[:person_id])
    render_resource Onsi::Resource.new(@person.emails.find(params[:id]), :v2)
  end
end
