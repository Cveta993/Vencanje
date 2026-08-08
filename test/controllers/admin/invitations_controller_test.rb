require "test_helper"

class Admin::InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "invitation-admin@example.com",
      password: "sigurna-lozinka",
      password_confirmation: "sigurna-lozinka"
    )
    @invitation = Invitation.create!(first_name: "Mila", last_name: "Milić", note: "Kumovi")
  end

  test "logged-out visitors are redirected from the dashboard" do
    get admin_invitations_path

    assert_redirected_to admin_login_path
  end

  test "dashboard shows status totals and names of every attending guest" do
    rsvp = @invitation.build_rsvp(attendance: :attending, message: "Jedva čekamo!", submitted_at: Time.current)
    rsvp.replace_guest_names(adult_names: [ "Mila Milić" ], child_names: [ "Luka Milić" ])
    rsvp.save!
    sign_in

    get admin_invitations_path

    assert_response :success
    assert_select "h2", text: "Mila Milić"
    assert_select ".status-badge--attending", text: "Dolaze"
    assert_select ".guest-list", text: /Mila Milić/
    assert_select ".guest-list", text: /Luka Milić/
    assert_select ".guest-message", text: /Jedva čekamo!/
    assert_select "input[value=?]", invitation_url(@invitation.access_token)
  end

  test "admin creates a personalized invitation link" do
    sign_in

    assert_difference("Invitation.count", 1) do
      post admin_invitations_path, params: {
        invitation: { first_name: "Ana", last_name: "Anić", note: "Sto broj 4" }
      }
    end

    created = Invitation.order(:id).last
    assert_redirected_to admin_invitation_path(created)
    assert_equal "Ana Anić", created.full_name
    assert created.access_token.present?
  end

  test "new, detail and edit pages render for an admin" do
    sign_in

    get new_admin_invitation_path
    assert_response :success
    assert_select "h1", "Nova pozivnica"

    get admin_invitation_path(@invitation)
    assert_response :success
    assert_select "h1", "Mila Milić"
    assert_select "input[value=?]", invitation_url(@invitation.access_token)

    get edit_admin_invitation_path(@invitation)
    assert_response :success
    assert_select "h1", "Mila Milić"
  end

  test "invalid invitation renders validation errors" do
    sign_in

    assert_no_difference("Invitation.count") do
      post admin_invitations_path, params: {
        invitation: { first_name: "", last_name: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors"
  end

  test "admin updates invitation details without changing its link" do
    sign_in
    original_token = @invitation.access_token

    patch admin_invitation_path(@invitation), params: {
      invitation: { first_name: "Milena", last_name: "Milić", note: "Izmenjena napomena" }
    }

    assert_redirected_to admin_invitation_path(@invitation)
    @invitation.reload
    assert_equal "Milena Milić", @invitation.full_name
    assert_equal "Izmenjena napomena", @invitation.note
    assert_equal original_token, @invitation.access_token
  end

  test "admin can invalidate the old link and generate a new one" do
    sign_in
    original_token = @invitation.access_token

    post regenerate_link_admin_invitation_path(@invitation)

    assert_redirected_to admin_invitation_path(@invitation)
    assert_not_equal original_token, @invitation.reload.access_token
  end

  test "admin deletes an invitation together with its RSVP and guest names" do
    rsvp = @invitation.build_rsvp(attendance: :attending, submitted_at: Time.current)
    rsvp.replace_guest_names(adult_names: [ "Mila Milić" ], child_names: [ "Luka Milić" ])
    rsvp.save!
    old_token = @invitation.access_token
    sign_in

    assert_difference("Invitation.count", -1) do
      assert_difference("Rsvp.count", -1) do
        assert_difference("RsvpGuest.count", -2) do
          delete admin_invitation_path(@invitation)
        end
      end
    end

    assert_response :see_other
    assert_redirected_to admin_invitations_path

    get invitation_path(old_token)
    assert_response :not_found
  end

  private

  def sign_in
    post admin_login_path, params: {
      email_address: @user.email_address,
      password: "sigurna-lozinka"
    }
  end
end
