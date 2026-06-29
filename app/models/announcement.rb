class Announcement < ApplicationRecord
  belongs_to :author, class_name: "User"
  has_many :announcement_reads, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :category, { general: 0, official: 1, finance: 2, welfare: 3, event: 4, urgent: 5 }, default: :general
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  validates :title, :body, :category, :status, presence: true

  scope :latest, -> { order(published_at: :desc, created_at: :desc) }
  scope :pinned, -> { where(pinned: true) }
  scope :by_category, ->(category) { categories.key?(category.to_s) ? where(category: category) : all }
  scope :by_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }
  scope :active, -> { published.where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :visible_to_members, -> { active.order(pinned: :desc, published_at: :desc, created_at: :desc) }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    next all if normalized_query.blank?

    pattern = "%#{sanitize_sql_like(normalized_query)}%"
    where("title ILIKE :query OR body ILIKE :query", query: pattern)
  }

  def read_by?(user)
    return false if user.blank?

    announcement_reads.exists?(user: user)
  end

  def unread_by?(user)
    !read_by?(user)
  end

  def mark_as_read_by!(user)
    return if user.blank?

    announcement_reads.find_or_create_by!(user: user) do |announcement_read|
      announcement_read.read_at = Time.current
    end
  end

  def publishable?
    !archived?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end
end
