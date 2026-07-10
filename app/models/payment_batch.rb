class PaymentBatch < ApplicationRecord
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

  before_validation :copy_total_amount

  scope :latest, -> { order(created_at: :desc) }
  scope :current_for_member, -> { where(status: [ :pending, :pending_verification, :rejected ]) }
  scope :reviewable, -> { where(status: :pending_verification) }

  def submit_bank_transfer!(transferred_on:, transfer_amount:, transfer_reference_name:, transfer_screenshot: nil)
    transaction do
      update!(
        status: :pending_verification,
        transferred_on: transferred_on,
        transfer_amount: transfer_amount,
        transfer_reference_name: transfer_reference_name
      )
      self.transfer_screenshot.attach(transfer_screenshot) if transfer_screenshot.present?
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
    end
  end

  def approve!(approver)
    transaction do
      update!(status: :paid, approved_by: approver, approved_at: Time.current)
      MembershipPayment.where(payment_batch_id: id).find_each do |payment|
        payment.approve!(approver)
      end
    end
  end

  def reject!(approver)
    transaction do
      update!(status: :rejected, approved_by: approver)
      membership_payments.find_each do |payment|
        payment.update!(status: :failed, approved_by: approver)
      end
    end
  end

  def cancel_by_member!
    transaction do
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
    end
  end

  def item_count
    membership_payments.size
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

  def validate_whole_yen(attribute, value)
    return if BigDecimal(value.to_s).frac.zero?

    errors.add(attribute, "must be a whole yen amount")
  rescue ArgumentError
    errors.add(attribute, "is not a number")
  end
end
