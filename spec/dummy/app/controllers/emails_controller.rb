class EmailsController < ApplicationController
  include Onsi::Controller
  include Onsi::ErrorResponder

  def index
    @person = Person.find(params[:person_id])
    render_resource @person.emails.to_a, version: params[:version].to_sym
  end

  def show
    @person = Person.find(params[:person_id])
    @email = @person.emails.find(params[:id])
    @includes = Onsi::Includes.new('person,messages')
    @includes.fetch_person { @person }
    @includes.fetch_messages { @email.messages }
    render_resource Onsi::Resource.new(@email, params[:version].to_sym, includes: @includes)
  end

  def create
    @person = Person.find(params[:person_id])
    attrs = Onsi::Params.parse(params, %i[address])
    attrs.require(:address)
    render_resource @person.emails.create!(attrs.flatten)
  end
end
