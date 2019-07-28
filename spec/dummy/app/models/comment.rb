class Comment < ActiveRecord::Base
  include Onsi::Model

  belongs_to :message
  belongs_to :parent, class_name: 'Comment', required: false

  has_many :children, class_name: 'Comment', foreign_key: :parent_id

  api_render(:v1) do
    attribute :body

    attribute :created_at
    attribute :updated_at

    relationship(:message, :message)
    relationship(:parent, :parent)
    relationship(:children, :children) { children.map(&:id) }
  end
end
