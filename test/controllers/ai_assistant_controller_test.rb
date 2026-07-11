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
    assert_includes response.body, "Payment receipt WhatsApp-ah ka dawn dan"
    assert_includes response.body, "Payment approved a nih ka hriat dan"
    assert_includes response.body, "Welfare request hi private a ni em?"
    assert_includes response.body, "Announcements/updates khawi atanga ka en ang?"
    assert_no_match(/Profile complete dan/, response.body)
    assert_no_match(/Japan mobile number eng format/, response.body)
  end

  test "signed in member can ask a payment question" do
    sign_in @member

    post ai_assistant_path, params: { question: "Membership fee engtin nge ka pek ang?" }

    assert_response :success
    assert_includes response.body, "Payment tih dan"
  end

  test "super admin receives management suggestions" do
    sign_in @admin

    get ai_assistant_path

    assert_response :success
    assert_includes response.body, "Super Admin tan portal hman dan kimchang"
    assert_includes response.body, "User roles thlak dan"
    assert_includes response.body, "Audit logs"
  end

  test "finance admin receives finance suggestions without settings suggestions" do
    treasurer = create_user("Treasurer User", "treasurer_ai@example.test", :treasurer)
    sign_in treasurer

    get ai_assistant_path

    assert_response :success
    assert_includes response.body, "Finance Admin tan portal hman dan"
    assert_includes response.body, "Pending transfer engtin nge ka verify ang?"
    assert_no_match(/User roles thlak dan/, response.body)
    assert_no_match(/Audit logs khawi/, response.body)
  end

  test "office bearer viewer receives view only guidance" do
    vice_president = create_user("Vice President", "vp_ai@example.test", :vice_president)
    sign_in vice_president

    with_openai_disabled do
      post ai_assistant_path, params: { question: "Ka role hian eng nge ka tih theih?" }
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
      post ai_assistant_path, params: { question: "Ka role hian eng nge ka tih theih?" }
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
