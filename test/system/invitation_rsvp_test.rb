require "application_system_test_case"

class InvitationRsvpTest < ApplicationSystemTestCase
  test "guest names are generated in the browser and the response can be edited" do
    invitation = Invitation.create!(first_name: "Milica", last_name: "Jovanović")

    visit invitation_path(invitation.access_token)

    assert_text "Aleksa & Valentina"

    find("#rsvp_attendance_attending", visible: :all).choose
    assert_field "Odrasla osoba 1", with: invitation.full_name
    select "2", from: "Broj odraslih"
    select "1", from: "Deca mlađa od 10 godina"

    assert_selector "input[name='rsvp[adult_names][]']", count: 2
    assert_selector "input[name='rsvp[child_names][]']", count: 1

    page.execute_script("document.documentElement.style.scrollBehavior = 'auto'; document.querySelector('#rsvp').scrollIntoView()")
    capture("invitation-desktop-rsvp-expanded")

    desktop_form_layout = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const form = document.querySelector(".rsvp-panel__form-wrap").getBoundingClientRect()
        const formStyle = getComputedStyle(document.querySelector(".rsvp-panel__form-wrap"))
        const deadline = document.querySelector(".rsvp-deadline").getBoundingClientRect()
        const adults = document.querySelector(".guest-names-section:not(.guest-names-section--children)").getBoundingClientRect()
        const children = document.querySelector(".guest-names-section--children").getBoundingClientRect()
        const nameInput = document.querySelector("input[name='rsvp[adult_names][]']")
        const nameInputRect = nameInput.getBoundingClientRect()
        const nameInputStyle = getComputedStyle(nameInput)
        const select = document.querySelector("#rsvp_adult_count")
        const adultSelectRect = select.getBoundingClientRect()
        const childSelectRect = document.querySelector("#rsvp_child_count").getBoundingClientRect()
        const childSection = document.querySelector(".guest-names-section--children")
        const childSectionRect = childSection.getBoundingClientRect()
        const dividerStyle = getComputedStyle(childSection, "::before")
        const dividerX = childSectionRect.left + Number.parseFloat(dividerStyle.left) +
          Number.parseFloat(dividerStyle.borderLeftWidth) / 2
        const countGapCenter = (adultSelectRect.right + childSelectRect.left) / 2
        const submit = document.querySelector(".rsvp-form .button--primary")

        return {
          formWidth: form.width,
          viewportWidth: window.innerWidth,
          formBackground: formStyle.backgroundColor,
          formShadow: formStyle.boxShadow,
          formBorderTopWidth: formStyle.borderTopWidth,
          deadlineLeft: deadline.left,
          deadlineRight: deadline.right,
          adultsTop: adults.top,
          adultsRight: adults.right,
          childrenTop: children.top,
          childrenLeft: children.left,
          nameInputBackground: nameInputStyle.backgroundColor,
          nameInputBorderTopWidth: nameInputStyle.borderTopWidth,
          nameInputBorderBottomWidth: nameInputStyle.borderBottomWidth,
          nameInputHeight: nameInputRect.height,
          selectTagName: select.tagName,
          selectHeight: select.getBoundingClientRect().height,
          adultSelectWidth: adultSelectRect.width,
          childSelectWidth: childSelectRect.width,
          dividerX: dividerX,
          countGapCenter: countGapCenter,
          dividerBorderStyle: dividerStyle.borderLeftStyle,
          dividerBorderWidth: Number.parseFloat(dividerStyle.borderLeftWidth),
          submitHeight: submit.getBoundingClientRect().height
        }
      })()
    JAVASCRIPT
    assert_operator desktop_form_layout["formWidth"], :>=, desktop_form_layout["viewportWidth"] * 0.98
    assert_equal "rgba(0, 0, 0, 0)", desktop_form_layout["formBackground"]
    assert_equal "none", desktop_form_layout["formShadow"]
    assert_equal "0px", desktop_form_layout["formBorderTopWidth"]
    assert_operator desktop_form_layout["deadlineLeft"], :>=, 0
    assert_operator desktop_form_layout["deadlineRight"], :<=, desktop_form_layout["viewportWidth"]
    assert_in_delta desktop_form_layout["adultsTop"], desktop_form_layout["childrenTop"], 2
    assert_operator desktop_form_layout["adultsRight"], :<, desktop_form_layout["childrenLeft"]
    assert_equal "rgba(0, 0, 0, 0)", desktop_form_layout["nameInputBackground"]
    assert_equal "0px", desktop_form_layout["nameInputBorderTopWidth"]
    assert_equal "1px", desktop_form_layout["nameInputBorderBottomWidth"]
    assert_equal "SELECT", desktop_form_layout["selectTagName"]
    assert_operator desktop_form_layout["nameInputHeight"], :>=, 44
    assert_operator desktop_form_layout["selectHeight"], :>=, 44
    assert_in_delta desktop_form_layout["adultSelectWidth"],
      desktop_form_layout["childSelectWidth"], 1
    assert_equal "solid", desktop_form_layout["dividerBorderStyle"]
    assert_operator desktop_form_layout["dividerBorderWidth"], :>=, 1
    assert_in_delta desktop_form_layout["countGapCenter"], desktop_form_layout["dividerX"], 1
    assert_operator desktop_form_layout["submitHeight"], :>=, 44

    page.execute_script("document.documentElement.style.scrollBehavior = 'auto'; window.scrollTo(0, document.documentElement.scrollHeight)")
    expanded_layout = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const form = document.querySelector(".rsvp-panel__form-wrap").getBoundingClientRect()
        const gallery = document.querySelector(".gallery-anchor").getBoundingClientRect()
        const plan = document.querySelector(".schedule-panel").getBoundingClientRect()
        const rsvp = document.querySelector(".rsvp-panel").getBoundingClientRect()
        const nav = document.querySelector(".invitation-nav").getBoundingClientRect()
        const upperPoint = document.elementFromPoint(12, Math.max(nav.bottom + 8, plan.top + 8))
        const lowerPoint = document.elementFromPoint(12, Math.min(window.innerHeight - 8, plan.bottom + 8))

        return {
          formBottom: form.bottom,
          galleryTop: gallery.top,
          galleryBottom: gallery.bottom,
          planTop: plan.top,
          planBottom: plan.bottom,
          rsvpBottom: rsvp.bottom,
          viewportHeight: window.innerHeight,
          upperShowsPlan: Boolean(upperPoint?.closest(".schedule-panel")),
          lowerShowsRsvp: Boolean(lowerPoint?.closest(".rsvp-panel"))
        }
      })()
    JAVASCRIPT
    assert_operator expanded_layout["formBottom"], :<=, expanded_layout["galleryTop"]
    assert_operator expanded_layout["galleryBottom"], :<=, expanded_layout["viewportHeight"] + 1
    assert_in_delta 0, expanded_layout["planTop"], 3
    assert_in_delta expanded_layout["viewportHeight"] / 3.0, expanded_layout["planBottom"], 3
    assert_in_delta expanded_layout["viewportHeight"] * 2.0 / 3.0,
      expanded_layout["viewportHeight"] - expanded_layout["planBottom"], 3
    assert_operator expanded_layout["rsvpBottom"], :<=, expanded_layout["viewportHeight"] + 1
    assert expanded_layout["upperShowsPlan"]
    assert expanded_layout["lowerShowsRsvp"]

    fill_in "Odrasla osoba 1", with: "Milica Jovanović"
    fill_in "Odrasla osoba 2", with: "Nikola Jovanović"
    fill_in "Dete 1", with: "Lena Jovanović"
    fill_in "Poruka za mladence (opciono)", with: "Jedva čekamo!"
    click_button "Pošalji odgovor"

    assert_text "Hvala, sačuvali smo vaš odgovor."
    assert_text "Vaš odgovor je sačuvan."
    assert_field "Odrasla osoba 2", with: "Nikola Jovanović"
    assert_field "Dete 1", with: "Lena Jovanović"

    select "1", from: "Broj odraslih"
    select "0", from: "Deca mlađa od 10 godina"
    click_button "Sačuvaj izmene"

    assert_text "Hvala, izmenili smo vaš odgovor."
    assert_equal 1, invitation.reload.rsvp.adult_count
    assert_equal 0, invitation.rsvp.child_count
  end

  private

  def capture(name)
    return unless ENV["CAPTURE_SCREENSHOTS"] == "1"

    page.driver.browser.save_screenshot(Rails.root.join("tmp/screenshots/#{name}.png").to_s)
  end
end
