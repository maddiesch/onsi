class Person < ActiveRecord::Base
  include Onsi::Model

  has_many :emails
  has_many :contacts

  validates :first_name, presence: true
  validates :last_name, presence: true

  api_render(:v1) do
    attribute :first_name
    attribute :last_name
  end

  api_render(:v2) do
    attribute :first_name
    attribute :last_name
    attribute :created_at
    attribute :updated_at
    attribute :birthdate
  end
end
