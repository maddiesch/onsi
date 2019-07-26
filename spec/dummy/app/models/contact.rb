class Contact < ActiveRecord::Base
  include Onsi::Model

  belongs_to :person

  api_render(:v1) do
    attribute :value

    attribute :created_at
    attribute :updated_at

    relationship :person, :person
  end
end
