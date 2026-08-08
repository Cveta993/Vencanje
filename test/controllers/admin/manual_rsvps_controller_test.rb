require "test_helper"

class Admin::ManualRsvpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "manual-rsvp-admin@example.com",
      password: "sigurna-lozinka",
      password_confirmation: "sigurna-lozinka"
    )
    @invitation = Invitation.create!(first_name: "Mila", last_name: "Milić")
  end

  test "manual RSVP form requires an admin session" do
    get edit_admin_invitation_rsvp_path(@invitation)

    assert_redirected_to admin_login_path
  end

  test "admin sees a prefilled form for a pending invitation" do
    sign_in

    get edit_admin_invitation_rsvp_path(@invitation)

    assert_response :success
    assert_select "h1", "Mila Milić"
    assert_select "form[action=?]", admin_invitation_rsvp_path(@invitation)
    assert_select "input[name='rsvp[adult_names][]'][value=?]", "Mila Milić"
  end

  test "admin records an attending response with every guest name" do
    sign_in

    assert_difference -> { Rsvp.count }, 1 do
      assert_difference -> { RsvpGuest.count }, 3 do
        post admin_invitation_rsvp_path(@invitation), params: {
          rsvp: {
            attendance: "attending",
            adult_count: "2",
            child_count: "1",
            adult_names: [ "Mila Milić", "Miloš Milić" ],
            child_names: [ "Lena Milić" ],
            message: "Potvrdili telefonom."
          }
        }
      end
    end

    assert_redirected_to admin_invitation_path(@invitation)
    rsvp = @invitation.reload.rsvp
    assert rsvp.attending?
    assert_equal [ "Mila Milić", "Miloš Milić" ], rsvp.adult_names
    assert_equal [ "Lena Milić" ], rsvp.child_names
    assert_equal "Potvrdili telefonom.", rsvp.message
  end

  test "admin changes an existing response to declined and clears guest names" do
    rsvp = @invitation.build_rsvp(attendance: :attending, submitted_at: Time.current)
    rsvp.replace_guest_names(adult_names: [ "Mila Milić" ], child_names: [ "Lena Milić" ])
    rsvp.save!
    sign_in

    assert_no_difference -> { Rsvp.count } do
      patch admin_invitation_rsvp_path(@invitation), params: {
        rsvp: {
          attendance: "declined",
          message: "Javili su porukom da ne dolaze."
        }
      }
    end

    assert_redirected_to admin_invitation_path(@invitation)
    assert @invitation.reload.rsvp.declined?
    assert_empty @invitation.rsvp.rsvp_guests
  end

  test "invalid manual response is not partially saved" do
    sign_in

    assert_no_difference [ "Rsvp.count", "RsvpGuest.count" ] do
      post admin_invitation_rsvp_path(@invitation), params: {
        rsvp: {
          attendance: "attending",
          adult_count: "1",
          child_count: "0",
          adult_names: [ "Mila" ],
          child_names: []
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /ime i prezime/i
  end

  private

  def sign_in
    post admin_login_path, params: {
      email_address: @user.email_address,
      password: "sigurna-lozinka"
    }
  end
end
