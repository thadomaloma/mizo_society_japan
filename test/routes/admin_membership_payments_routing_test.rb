require "test_helper"

class AdminMembershipPaymentsRoutingTest < ActionDispatch::IntegrationTest
  test "routes admin new membership payment page" do
    assert_routing(
      "/admin/payments/new",
      controller: "admin/membership_payments",
      action: "new"
    )
  end

  test "redirects old member payment URLs to clean payment URLs" do
    get "/membership_payments/12"

    assert_redirected_to "/payments/12"
  end

  test "redirects old admin payment URLs to clean admin payment URLs" do
    get "/admin/membership_payments/new"

    assert_redirected_to "/admin/payments/new"
  end
end
