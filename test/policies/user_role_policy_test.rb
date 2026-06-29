require "test_helper"

class UserRolePolicyTest < ActiveSupport::TestCase
  test "only president and secretary can manage user roles" do
    allowed_roles = %w[president secretary]

    User::ROLES.each_key do |role|
      policy = UserRolePolicy.new(User.new(role: role), :user_role)

      assert_equal allowed_roles.include?(role.to_s), policy.index?, "#{role} index access mismatch"
      assert_equal allowed_roles.include?(role.to_s), policy.update?, "#{role} update access mismatch"
      assert_equal allowed_roles.include?(role.to_s), policy.create?, "#{role} create access mismatch"
    end
  end
end
