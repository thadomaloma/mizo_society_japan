class MembershipPlanType < ApplicationRecord
  DEFAULT_CODES = %w[membership donation fundraiser other_fee].freeze

  has_many :membership_plans, dependent: :restrict_with_error

  before_validation :normalize_name
  before_validation :assign_code, on: :create

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validate :membership_type_remains_active

  scope :active, -> { where(active: true) }
  scope :latest, -> { order(:name) }
  scope :membership, -> { where(code: "membership") }

  def default?
    code.in?(DEFAULT_CODES)
  end

  private

  def normalize_name
    self.name = name.to_s.squish
  end

  def assign_code
    return if code.present?

    base = name.to_s.parameterize(separator: "_").presence || "plan_type"
    candidate = base
    suffix = 2

    while self.class.where.not(id: id).exists?(code: candidate)
      candidate = "#{base}_#{suffix}"
      suffix += 1
    end

    self.code = candidate
  end

  def membership_type_remains_active
    return unless code == "membership" && !active?

    errors.add(:active, "must remain active for member payments")
  end
end
