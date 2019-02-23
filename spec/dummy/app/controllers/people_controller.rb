class PeopleController < ApplicationController
  include Onsi::Controller
  include Onsi::ErrorResponder

  def index
    render_resource Person.all, version: params[:version].to_sym
  end

  def create
    attributes = %i[
      first_name
      last_name
    ]
    relationships = [
      { email: [:address] }
    ]
    params = Onsi::Params.parse_json(request.body, attributes, relationships)
    person = Person.create!(
      first_name: params.require(:first_name),
      last_name: params.require(:last_name)
    )
    email = person.emails.create!(
      address: params.require_path('email/address')
    )
    render_resource([person, email], status: :created)
  end
end
