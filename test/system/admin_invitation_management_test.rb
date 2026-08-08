require "application_system_test_case"

class AdminInvitationManagementTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email_address: "admin@example.com",
      password: "sigurna-lozinka-123",
      password_confirmation: "sigurna-lozinka-123"
    )
  end

  test "admin signs in and creates a personalized invitation link" do
    sign_in

    assert_text "Pozivnice i odgovori"
    click_link "Nova pozivnica", match: :first
    fill_in "Ime", with: "Ana"
    fill_in "Prezime", with: "Petrović"
    fill_in "Interna napomena", with: "Porodica Petrović"
    click_button "Napravi pozivnicu"

    assert_text "Pozivnica je kreirana. Link je spreman za slanje."
    assert_text "Ana Petrović"
    assert_field "Pun link pozivnice", with: %r{/pozivnica/[A-Za-z0-9_-]+}
    capture_admin
  end

  test "admin manually records and edits a guest response" do
    invitation = Invitation.create!(first_name: "Mila", last_name: "Milić")
    sign_in

    visit admin_invitation_path(invitation)
    click_link "Unesi odgovor"

    choose "Dolaze"
    select "2", from: "Broj odraslih"
    select "1", from: "Deca mlađa od 10 godina"
    assert_selector "input[name='rsvp[adult_names][]']", count: 2
    assert_selector "input[name='rsvp[child_names][]']", count: 1

    fill_in "Odrasla osoba 1", with: "Mila Milić"
    fill_in "Odrasla osoba 2", with: "Miloš Milić"
    fill_in "Dete 1", with: "Lena Milić"
    fill_in "Poruka koju je gost poslao (opciono)", with: "Potvrdili porukom."
    capture_admin("admin-manual-rsvp")
    click_button "Sačuvaj odgovor"

    assert_text "Odgovor je sačuvan ručno."
    assert_text "Miloš Milić"
    assert_text "Lena Milić"
    assert_link "Izmeni odgovor"
    assert_equal 3, invitation.reload.rsvp.rsvp_guests.count
  end

  private

  def sign_in
    visit admin_login_path
    fill_in "Email adresa", with: @user.email_address
    fill_in "Lozinka", with: "sigurna-lozinka-123"
    click_button "Prijavi se"
    assert_text "Pozivnice i odgovori"
  end

  def capture_admin(name = "admin-invitation")
    return unless ENV["CAPTURE_SCREENSHOTS"] == "1"

    page.driver.browser.save_screenshot(Rails.root.join("tmp/screenshots/#{name}.png").to_s)
  end
end
