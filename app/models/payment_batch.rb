class PaymentBatch < ApplicationRecord
  include AttachmentValidation

  TRANSFER_PROOF_CONTENT_TYPES = MembershipPayment::TRANSFER_PROOF_CONTENT_TYPES
  TRANSFER_PROOF_MAX_SIZE = MembershipPayment::TRANSFER_PROOF_MAX_SIZE

  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :membership_payments, dependent: :nullify
  has_one_attached :transfer_screenshot

  enum :status, {
    pending: 0,
    pending_verification: 1,
    paid: 2,
    rejected: 3,
    cancelled: 4
  }, default: :pending

  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :transfer_amount, allow_blank: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validate :payments_belong_to_user
  validate :amounts_are_whole_yen
  validate :transfer_screenshot_is_safe

  before_validation :copy_total_amount
  after_commit -> { DashboardCache.expire_payments }

  scope :latest, -> { order(created_at: :desc) }
  scope :current_for_member, -> { where(status: [ :pending, :pending_verification, :rejected ]) }
  scope :reviewable, -> { where(status: :pending_verification) }

  def submit_bank_transfer!(transferred_on:, transfer_amount:, transfer_reference_name:, transfer_screenshot: nil)
    with_lock do
      return false if pending_verification?
      unless pending? || rejected?
        errors.add(:status, "does not allow a bank transfer submission")
        raise ActiveRecord::RecordInvalid, self
      end
      if membership_payments.empty?
        errors.add(:membership_payments, "must include at least one payment")
        raise ActiveRecord::RecordInvalid, self
      end

      submitted_amount = BigDecimal(transfer_amount.to_s)
      unless submitted_amount == total_amount
        errors.add(:transfer_amount, "must match the combined payment total")
        raise ActiveRecord::RecordInvalid, self
      end

      assign_attributes(
        status: :pending_verification,
        transferred_on: transferred_on,
        transfer_amount: submitted_amount,
        transfer_reference_name: transfer_reference_name
      )
      self.transfer_screenshot.attach(transfer_screenshot) if transfer_screenshot.present?
      save!
      membership_payments.find_each do |payment|
        payment.update!(
          payment_method: :manual_bank_transfer,
          status: :pending_verification,
          transferred_on: transferred_on,
          transfer_amount: payment.amount,
          transfer_reference_name: transfer_reference_name,
          reference_number: transfer_reference_name
        )
      end
      true
    end
  end

  def approve!(approver)
    with_lock do
      return false if paid?
      unless pending_verification?
        errors.add(:status, "must be pending verification before approval")
        raise ActiveRecord::RecordInvalid, self
      end

      update!(status: :paid, approved_by: approver, approved_at: Time.current)
      MembershipPayment.where(payment_batch_id: id).find_each do |payment|
        payment.approve!(approver)
      end
      true
    end
  end

  def reject!(approver)
    with_lock do
      return false if rejected?
      unless pending_verification?
        errors.add(:status, "must be pending verification before rejection")
        raise ActiveRecord::RecordInvalid, self
      end

      update!(status: :rejected, approved_by: approver)
      membership_payments.find_each do |payment|
        payment.update!(status: :failed, approved_by: approver)
      end
      true
    end
  end

  def cancel_by_member!
    with_lock do
      return false if cancelled?
      unless pending? || rejected?
        errors.add(:status, "does not allow cancellation")
        raise ActiveRecord::RecordInvalid, self
      end

      membership_payments.find_each do |payment|
        payment.update!(
          payment_batch: nil,
          status: :pending,
          transferred_on: nil,
          transfer_amount: nil,
          transfer_reference_name: nil
        )
      end
      update!(status: :cancelled)
      true
    end
  end

  def item_count
    membership_payments.size
  end

  def receipt_number
    "MSJ-B-#{id.to_s.rjust(6, '0')}"
  end

  def receipt_date
    approved_at&.to_date || updated_at.to_date
  end

  def receipt_total
    total_amount
  end

  def receipt_reference
    transfer_reference_name.presence || "-"
  end

  def receipt_payment_method
    "Bank transfer"
  end

  def receipt_payments
    membership_payments
  end

  private

  def copy_total_amount
    self.total_amount = membership_payments.sum(:amount) if membership_payments.loaded? || membership_payments.exists?
  end

  def payments_belong_to_user
    return if user.blank?

    errors.add(:membership_payments, "must belong to the same member") if membership_payments.any? { |payment| payment.user_id != user_id }
  end

  def amounts_are_whole_yen
    validate_whole_yen(:total_amount, total_amount)
    validate_whole_yen(:transfer_amount, transfer_amount) if transfer_amount.present?
  end

  def transfer_screenshot_is_safe
    validate_attachment_upload(
      transfer_screenshot,
      attribute: :transfer_screenshot,
      content_types: TRANSFER_PROOF_CONTENT_TYPES,
      max_size: TRANSFER_PROOF_MAX_SIZE
    )
  end

  def validate_whole_yen(attribute, value)
    return if BigDecimal(value.to_s).frac.zero?

    errors.add(attribute, "must be a whole yen amount")
  rescue ArgumentError
    errors.add(attribute, "is not a number")
  end
end
