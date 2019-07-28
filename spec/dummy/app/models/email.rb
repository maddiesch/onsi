class Email < ActiveRecord::Base
  include Onsi::Model

  belongs_to :person

  validates :address, presence: true, uniqueness: { scope: :person_id }, format: { with: %r{\A(.*)@(.*)\.(.*)\z} }

  has_many :messages, dependent: :destroy

  api_render(:v1) do
    legacy_relationship_render!

    attribute :address
    attribute :created_at
    attribute :updated_at

    relationship :person, :person

    relationship(:messages, :message) { messages.map(&:id) }
    relationship(:invalid, :invalid) { nil }

    meta(:validated) { true }
  end
end
