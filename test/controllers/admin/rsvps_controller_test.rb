require "test_helper"
require "csv"

class Admin::RsvpsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "export-admin@example.com",
      password: "sigurna-lozinka",
      password_confirmation: "sigurna-lozinka"
    )

    attending = Invitation.create!(first_name: "Ana", last_name: "Anić")
    rsvp = attending.build_rsvp(attendance: :attending, message: "Vidimo se!", submitted_at: Time.zone.parse("2026-08-08 12:30"))
    rsvp.replace_guest_names(adult_names: [ "Ana Anić" ], child_names: [ "Mia Anić" ])
    rsvp.save!

    Invitation.create!(first_name: "Bez", last_name: "Odgovora")
    Invitation.create!(first_name: "Neven", last_name: "Nevenić")
      .create_rsvp!(attendance: :declined, message: "Žao nam je.", submitted_at: Time.zone.parse("2026-08-08 13:00"))
  end

  test "CSV requires an admin session" do
    get admin_rsvps_export_path(format: :csv)

    assert_redirected_to admin_login_path
  end

  test "CSV has one row per guest plus rows for declined and unanswered invitations" do
    sign_in

    get admin_rsvps_export_path(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/attachment/, response.headers["Content-Disposition"])

    rows = CSV.parse(response.body.delete_prefix("\uFEFF"), headers: true)
    assert_equal 4, rows.size

    adult = rows.find { |row| row["Ime gosta"] == "Ana Anić" }
    child = rows.find { |row| row["Ime gosta"] == "Mia Anić" }
    declined = rows.find { |row| row["Pozivnica za"] == "Neven Nevenić" }
    pending = rows.find { |row| row["Pozivnica za"] == "Bez Odgovora" }

    assert_equal "Odrasla osoba", adult["Kategorija gosta"]
    assert_equal "Dete mlađe od 10 godina", child["Kategorija gosta"]
    assert_equal "Ne dolaze", declined["Status"]
    assert_nil declined["Ime gosta"]
    assert_equal "Čeka se odgovor", pending["Status"]
    assert_nil pending["Ime gosta"]
  end

  private

  def sign_in
    post admin_login_path, params: {
      email_address: @user.email_address,
      password: "sigurna-lozinka"
    }
  end
end
