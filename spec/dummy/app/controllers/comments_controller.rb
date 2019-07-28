class CommentsController < ApplicationController
  include Onsi::Controller
  include Onsi::ErrorResponder

  def index
    render_resource(Message.find(params[:message_id]).comments)
  end
end
