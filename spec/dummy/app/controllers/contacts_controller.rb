class ContactsController < ApplicationController
  include Onsi::Controller
  include Onsi::ErrorResponder

  def index
    @person = Person.find(params[:person_id])
    results = Onsi::Paginate.perform(
      @person.contacts,
      'contacts',
      params
    )
    render_resource(results)
  end
end
