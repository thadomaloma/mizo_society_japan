class BackfillFinanceTransactionsForPaidMembershipPayments < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Backfilling finance transactions for paid membership payments" do
      MembershipPayment
        .paid
        .includes(:approved_by, :user, membership_plan: :membership_plan_type)
        .find_each do |payment|
          MembershipPaymentFinanceRecorder.call(payment: payment, actor: payment.approved_by)
        end
    end
  end

  def down
    # Data backfill is intentionally irreversible.
  end
end
