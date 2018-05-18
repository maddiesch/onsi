class MessagesController < ApplicationController
  include Onsi::Controller
  include Onsi::ErrorResponder

  def index
    @person = Person.find(params[:person_id])
    @email = @person.emails.find(params[:email_id])
    render_resource @email.messages, version: params[:version].to_sym
  end

  def create
    @person = Person.find(params[:person_id])
    @email = @person.emails.find(params[:email_id])
    attributes = Onsi::Params.parse(params, [:body], [:to])
    @to = attributes.safe_fetch(:to_id) { |id| Person.find(id) }
    head :no_content
  end
end
