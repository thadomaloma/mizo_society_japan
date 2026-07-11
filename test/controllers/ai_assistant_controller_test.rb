require "test_helper"

class AiAssistantControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @admin = users(:admin)
  end

  test "signed in member can open ai assistant even before profile is complete" do
    sign_in @member

    get ai_assistant_path

    assert_response :success
    assert_select "h2", "AI Assistant"
    assert_includes response.body, "Transfer zawh hnuah eng nge ka submit a, status engtin nge ka check ang?"
    assert_includes response.body, "Welfare support private taka engtin nge ka dil ang?"
    assert_includes response.body, "Events, RSVP leh announcements engtin nge ka hman ang?"
    assert_no_match(/Profile complete dan/, response.body)
    assert_no_match(/Japan mobile number eng format/, response.body)
  end

  test "signed in member can ask a payment question" do
    sign_in @member

    post ai_assistant_path, params: { question: "Fee leh fund te vawi khat bank transfer-in engtin nge ka pek ang?" }

    assert_response :success
    assert_includes response.body, "Payment tih dan"
  end

  test "super admin receives management suggestions" do
    sign_in @admin

    get ai_assistant_path

    assert_response :success
    assert_includes response.body, "Super Admin daily checklist"
    assert_includes response.body, "User role assign, change leh deactivate"
    assert_includes response.body, "Settings, Permissions leh Audit Logs"
    assert_no_match(/Member account hian eng nge/, response.body)
  end

  test "finance admin receives finance suggestions without settings suggestions" do
    treasurer = create_user("Treasurer User", "treasurer_ai@example.test", :treasurer)
    sign_in treasurer

    get ai_assistant_path

    assert_response :success
    assert_includes response.body, "Finance Admin daily workflow"
    assert_includes response.body, "Combined transfer verify, approve leh reject"
    assert_no_match(/User role assign/, response.body)
    assert_no_match(/Audit Logs hman dan/, response.body)
  end

  test "office bearer viewer receives view only guidance" do
    vice_president = create_user("Vice President", "vp_ai@example.test", :vice_president)
    sign_in vice_president

    with_openai_disabled do
      post ai_assistant_path, params: { question: "Vice President/Journal Secretary access leh responsibility eng nge?" }
    end

    assert_response :success
    assert_includes response.body, "Vice President/Journal Secretary"
    assert_includes response.body, "view-only"
    assert_includes response.body, "Own Payments"
  end

  test "executive member receives view only guidance" do
    executive = create_user("Executive User", "executive_ai@example.test", :executive_member)
    sign_in executive

    with_openai_disabled do
      post ai_assistant_path, params: { question: "Executive Committee member access leh responsibility eng nge?" }
    end

    assert_response :success
    assert_includes response.body, "Executive Committee member"
    assert_includes response.body, "view-only"
    assert_includes response.body, "CSV export"
  end

  test "member asking admin approval gets denied clearly" do
    sign_in @member

    with_openai_disabled do
      post ai_assistant_path, params: { question: "Payment approve dan min hrilh rawh." }
    end

    assert_response :success
    assert_includes response.body, "available lo"
    assert_includes response.body, "Office Bearer"
  end

  test "every role receives a deduplicated question and answer catalog" do
    users = [
      @member,
      @admin,
      create_user("Treasurer Catalog", "treasurer_catalog@example.test", :treasurer),
      create_user("Assistant Catalog", "assistant_catalog@example.test", :assistant_secretary),
      create_user("Vice President Catalog", "vp_catalog@example.test", :vice_president),
      create_user("Executive Catalog", "executive_catalog@example.test", :executive_member)
    ]

    users.each do |user|
      entries = MizoAiAssistant.question_entries(user: user)

      assert_equal entries.size, entries.pluck(:key).uniq.size, "duplicate keys for #{user.role}"
      assert_equal entries.size, entries.pluck(:text).uniq.size, "duplicate questions for #{user.role}"
      assert_equal entries.size, entries.pluck(:answer).uniq.size, "duplicate answer intents for #{user.role}"

      entries.each do |entry|
        answer = MizoAiAssistant.call(user: user, question: entry.fetch(:text))
        assert answer.present?, "blank answer for #{user.role}: #{entry[:key]}"
        assert_match(/1\./, answer, "answer is not step-based for #{user.role}: #{entry[:key]}")
      end
    end
  end

  private

  def create_user(name, email, role)
    User.create!(
      name: name,
      email: email,
      role: role,
      password: "password123"
    )
  end

  def with_openai_disabled
    previous_key = ENV["OPENAI_API_KEY"]
    ENV.delete("OPENAI_API_KEY")
    yield
  ensure
    ENV["OPENAI_API_KEY"] = previous_key if previous_key.present?
  end
end
