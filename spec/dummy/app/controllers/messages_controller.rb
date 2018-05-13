class MessagesController < ApplicationController
  include Onsi::Controller

  def index_v1
    @person = Person.find(params[:person_id])
    @email = @person.emails.find(params[:email_id])
    render_resource @email.messages
  end
end
