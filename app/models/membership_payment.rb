class MembershipPayment < ApplicationRecord
  CURRENT_STATUSES = %i[pending pending_verification failed expired].freeze
  HISTORY_STATUSES = %i[paid cancelled refunded].freeze
  DUPLICATE_BLOCKING_STATUSES = %i[pending pending_verification failed expired paid].freeze

  belongs_to :user
  belongs_to :membership_plan
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :payment_batch, optional: true

  has_one_attached :transfer_screenshot
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :payment_method, { cash: 0, bank_transfer: 1, other: 3, manual_bank_transfer: 4 }, default: :bank_transfer
  enum :status, {
    pending: 0,
    paid: 3,
    failed: 4,
    expired: 5,
    cancelled: 6,
    refunded: 7,
    pending_verification: 8
  }, default: :pending

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :transfer_amount, allow_blank: true, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_year, numericality: { only_integer: true, greater_than_or_equal_to: 2000 }
  validates :payment_month, allow_blank: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :payment_method, :status, presence: true
  validate :amounts_are_whole_yen
  validate :no_duplicate_active_payment_for_plan

  before_validation :copy_plan_amount, if: -> { amount.blank? && membership_plan.present? }
  before_validation :assign_payment_year, if: -> { payment_year.blank? }

  scope :latest, -> { order(created_at: :desc) }
  scope :unpaid, -> { where(status: [ :pending, :pending_verification, :failed, :expired, :cancelled ]) }
  scope :current_for_member, -> { where(status: CURRENT_STATUSES) }
  scope :history_for_member, -> { where(status: HISTORY_STATUSES) }
  scope :by_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }
  scope :by_year, ->(year) { year.present? ? where(payment_year: year) : all }
  scope :for_user, ->(user) { where(user: user) }
  scope :membership_dues, -> { joins(membership_plan: :membership_plan_type).where(membership_plan_types: { code: "membership" }) }
  scope :by_plan_type, ->(plan_type_id) { plan_type_id.present? ? joins(:membership_plan).where(membership_plans: { membership_plan_type_id: plan_type_id }) : all }
  scope :search, lambda { |query|
    normalized_query = query.to_s.strip
    next all if normalized_query.blank?

    pattern = "%#{sanitize_sql_like(normalized_query)}%"
    left_joins(user: :member_profile)
      .where(
        "membership_payments.reference_number ILIKE :query OR users.email ILIKE :query OR users.name ILIKE :query OR member_profiles.full_name ILIKE :query OR member_profiles.membership_number ILIKE :query",
        query: pattern
      )
  }

  def approve!(approver)
    update!(status: :paid, approved_by: approver, paid_on: paid_on || Time.current)
  end

  def reject!(approver)
    update!(status: :failed, approved_by: approver)
  end

  def bank_transfer_submittable?
    user.present? && amount.to_i.positive? && (pending? || failed? || expired? || cancelled?)
  end

  def submit_bank_transfer!(transferred_on:, transfer_amount:, transfer_reference_name:, transfer_screenshot: nil)
    assign_attributes(
      payment_method: :manual_bank_transfer,
      status: :pending_verification,
      transferred_on: transferred_on,
      transfer_amount: transfer_amount,
      transfer_reference_name: transfer_reference_name,
      reference_number: transfer_reference_name
    )
    self.transfer_screenshot.attach(transfer_screenshot) if transfer_screenshot.present?
    save!
  end

  def finance_reference_number
    transfer_reference_name.presence || reference_number.presence || "membership-payment-#{id}"
  end

  def period_label
    return "One-time payment" if one_time_payment?

    [ payment_year, payment_month&.to_s&.rjust(2, "0") ].compact.join("/")
  end

  def plan_type_label
    membership_plan.plan_type_label
  end

  def membership_due?
    membership_plan.membership?
  end

  def one_time_payment?
    !membership_due? || membership_plan.one_time?
  end

  private

  def copy_plan_amount
    self.amount = membership_plan.amount
  end

  def assign_payment_year
    self.payment_year = Date.current.year
  end

  def amounts_are_whole_yen
    validate_whole_yen(:amount, amount)
    validate_whole_yen(:transfer_amount, transfer_amount) if transfer_amount.present?
  end

  def validate_whole_yen(attribute, value)
    return if BigDecimal(value.to_s).frac.zero?

    errors.add(attribute, "must be a whole yen amount")
  rescue ArgumentError
    errors.add(attribute, "is not a number")
  end

  def no_duplicate_active_payment_for_plan
    return if user_id.blank? || membership_plan_id.blank?
    return if cancelled? || refunded?

    duplicate_scope = self.class
      .where(user_id: user_id, membership_plan_id: membership_plan_id, status: DUPLICATE_BLOCKING_STATUSES)
      .where.not(id: id)

    duplicate_scope = if membership_plan&.one_time?
      duplicate_scope
    else
      duplicate_scope.where(payment_year: payment_year, payment_month: payment_month)
    end

    return unless duplicate_scope.exists?

    errors.add(:base, duplicate_payment_error_message)
  end

  def duplicate_payment_error_message
    plan_name = membership_plan&.name || "this payment plan"
    period = membership_plan&.one_time? ? "one-time payment" : period_label

    "#{plan_name} already has an active or paid payment record for #{period}. Use the existing record instead of creating another one."
  end
end
