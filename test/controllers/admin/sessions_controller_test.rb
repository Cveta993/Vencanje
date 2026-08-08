require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "admin@example.com",
      password: "sigurna-lozinka",
      password_confirmation: "sigurna-lozinka"
    )
  end

  test "login page is available without a session" do
    get admin_login_path

    assert_response :success
    assert_select "h1", "Dobro došli"
  end

  test "valid credentials start an admin session" do
    post admin_login_path, params: {
      email_address: " ADMIN@example.com ",
      password: "sigurna-lozinka"
    }

    assert_redirected_to admin_root_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Pozivnice i odgovori"
  end

  test "invalid credentials render the form with an error" do
    post admin_login_path, params: {
      email_address: @user.email_address,
      password: "pogresna-lozinka"
    }

    assert_response :unprocessable_entity
    assert_select "[role=status]", text: /nisu ispravni/
  end

  test "logout clears the admin session" do
    sign_in

    delete admin_logout_path

    assert_redirected_to admin_login_path
    get admin_root_path
    assert_redirected_to admin_login_path
  end

  private

  def sign_in
    post admin_login_path, params: {
      email_address: @user.email_address,
      password: "sigurna-lozinka"
    }
  end
end
