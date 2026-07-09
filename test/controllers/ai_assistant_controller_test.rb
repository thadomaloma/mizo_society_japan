require "test_helper"

class AiAssistantControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
  end

  test "signed in member can open ai assistant even before profile is complete" do
    sign_in @member

    get ai_assistant_path

    assert_response :success
    assert_select "h2", "AI Assistant"
  end

  test "signed in member can ask a payment question" do
    sign_in @member

    post ai_assistant_path, params: { question: "Membership fee engtin nge ka pek ang?" }

    assert_response :success
    assert_includes response.body, "Payment tih dan"
  end
end
