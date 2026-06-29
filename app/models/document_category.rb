class DocumentCategory < ApplicationRecord
  has_many :documents, dependent: :restrict_with_error

  before_validation :normalize_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  private

  def normalize_name
    self.name = name.to_s.squish
  end
end
