class WelfareNote < ApplicationRecord
  belongs_to :welfare_case
  belongs_to :user

  validates :body, presence: true

  scope :latest, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :internal, -> { where(internal: true) }
  scope :public_notes, -> { where(internal: false) }
end
