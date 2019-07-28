class Message < ActiveRecord::Base
  include Onsi::Model

  belongs_to :email

  has_many :comments

  api_render(:v1) do
    attribute :sent_at

    attribute :created_at
    attribute :updated_at

    relationship(:email, :email) { email_id }
  end
end
