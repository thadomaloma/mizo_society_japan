require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "Google OAuth links a verified email to its existing account" do
    user = users(:member)
    auth = google_auth(email: user.email, uid: "verified-google-user")

    result = User.from_google_oauth2(auth)

    assert_equal user, result
    assert_equal "google_oauth2", result.provider
    assert_equal "verified-google-user", result.uid
  end

  test "Google OAuth rejects an unverified email" do
    auth = google_auth(email: "unverified@example.test", uid: "unverified-google-user", verified: false)

    assert_no_difference -> { User.count } do
      result = User.from_google_oauth2(auth)

      assert_not result.persisted?
      assert_includes result.errors[:email], "must be verified by Google"
    end
  end

  test "role helper groups match MSJ permissions" do
    president = User.new(role: :president)
    vice_president = User.new(role: :vice_president)
    secretary = User.new(role: :secretary)
    treasurer = User.new(role: :treasurer)
    finance_secretary = User.new(role: :finance_secretary)
    assistant_secretary = User.new(role: :assistant_secretary)
    journal_secretary = User.new(role: :journal_secretary)
    executive_member = User.new(role: :executive_member)
    member = User.new(role: :member)

    assert president.super_admin?
    assert vice_president.office_bearer?
    assert secretary.super_admin?
    assert treasurer.finance_admin?
    assert finance_secretary.finance_admin?
    assert president.welfare_manager?
    assert secretary.welfare_manager?
    assert vice_president.welfare_viewer?
    assert executive_member.welfare_viewer?
    assert assistant_secretary.content_admin?
    assert_not vice_president.content_admin?
    assert_not journal_secretary.content_admin?
    assert president.event_manager?
    assert secretary.event_manager?
    assert assistant_secretary.event_manager?
    assert_not journal_secretary.event_manager?
    assert assistant_secretary.welfare_manager?
    assert assistant_secretary.minute_manager?
    assert_not vice_president.executive_committee?
    assert executive_member.executive_committee?
    assert_not journal_secretary.executive_committee?
    assert vice_president.minutes_access?
    assert executive_member.minutes_access?
    assert journal_secretary.minutes_access?
    assert member.member?
    assert_not vice_president.super_admin?
    assert vice_president.finance_viewer?
    assert vice_president.finance_observer?
    assert vice_president.report_viewer?
    assert_not vice_president.finance_team?
    assert_not vice_president.finance_approver?
    assert_not executive_member.office_bearer?
    assert_not member.minutes_access?
    assert_not treasurer.super_admin?
    assert treasurer.finance_viewer?
    assert finance_secretary.finance_approver?
    assert_not assistant_secretary.finance_admin?
    assert_not treasurer.welfare_viewer?
    assert_not journal_secretary.finance_team?
    assert journal_secretary.finance_viewer?
    assert journal_secretary.finance_observer?
    assert journal_secretary.welfare_viewer?
    assert_equal vice_president.advisory_viewer?, journal_secretary.advisory_viewer?
    assert_equal vice_president.operations_team?, journal_secretary.operations_team?
    assert_equal vice_president.finance_viewer?, journal_secretary.finance_viewer?
    assert_equal vice_president.welfare_viewer?, journal_secretary.welfare_viewer?
    assert_equal vice_president.report_viewer?, journal_secretary.report_viewer?
    assert_equal vice_president.minutes_access?, journal_secretary.minutes_access?
    assert journal_secretary.operations_team?
    assert_not executive_member.operations_team?
    assert vice_president.operations_team?
    assert president.operations_team?
    assert assistant_secretary.operations_team?
    assert treasurer.operations_team?
    assert finance_secretary.operations_team?
    assert_not member.event_manager?
  end

  test "assistant secretary role displays correctly" do
    assert_equal "Assistant Secretary", User.role_label(:assistant_secretary)
  end

  test "office bearer roles match MSJ office bearers" do
    office_bearers = %w[
      president
      vice_president
      secretary
      assistant_secretary
      treasurer
      finance_secretary
      journal_secretary
    ]

    User::ROLES.each_key do |role|
      assert_equal office_bearers.include?(role.to_s), User.new(role: role).office_bearer?
    end
  end

  private

  def google_auth(email:, uid:, verified: true)
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, name: "Google Member" },
      extra: { raw_info: { email_verified: verified } }
    )
  end
end
