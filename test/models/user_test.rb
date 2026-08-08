require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and authenticates a password" do
    user = User.create!(
      email_address: "  ADMIN@Example.com ",
      password: "a sufficiently long password",
      password_confirmation: "a sufficiently long password"
    )

    assert_equal "admin@example.com", user.email_address
    assert user.authenticate("a sufficiently long password")
    assert_not user.authenticate("wrong password")
  end
end
