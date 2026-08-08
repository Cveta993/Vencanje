require "test_helper"

class PublicInvitationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @invitation = Invitation.create!(
      first_name: "Milica",
      last_name: "Jovanović",
      note: "Interna napomena — ne prikazivati gostu"
    )
  end

  test "root page does not expose an invitation without its personal link" do
    get root_path

    assert_response :success
    assert_select "h1", "Dobro nam došli"
    assert_select "meta[name=robots][content=?]", "noindex, nofollow, noarchive", visible: false
    assert_not_includes response.body, @invitation.full_name
  end

  test "personal token renders one-page invitation without the internal note" do
    get invitation_path(@invitation.access_token)

    assert_response :success
    assert_select "main.invitation-page"
    assert_select "h1", text: /Aleksa & Valentina/
    assert_select ".hero-panel__date", text: "29.05.2027."
    assert_select ".event-card", count: 3
    assert_select ".event-card", text: /Crkveno venčanje.*Zemun Polje.*16:00/m
    assert_select ".event-card", text: /Skup svatova.*U restoranu.*17:00/m
    assert_select ".event-card", text: /Opštinsko venčanje.*U restoranu.*18:00/m
    assert_select ".rsvp-deadline", text: /15\.05\.2027\..*Dve nedelje pre venčanja/m
    assert_select ".hero-panel__invited strong", @invitation.full_name
    assert_select ".hero-panel__photo img[src*='hero-hug']"
    assert_select ".schedule-panel__photo img[src*='schedule-bled']"
    assert_select ".rsvp-panel__photo img[src*='rsvp-childhood']"
    assert_select "nav.invitation-nav[aria-label=?]", "Navigacija pozivnice" do
      assert_select "a.invitation-nav__brand[href='#top']", "Aleksa & Valentina"
      assert_select "a[href='#top']", "Početak"
      assert_select "a[href='#plan']", "Plan"
      assert_select "a[href='#rsvp']", "Potvrda"
      assert_select "a[href='#gallery']", "Galerija"
    end
    assert_select "section#top[aria-labelledby='invitation-title']"
    assert_select "#plan"
    assert_select "#rsvp form[action=?]", invitation_rsvp_path(@invitation.access_token)
    assert_select "span#gallery.gallery-anchor[aria-hidden='true']", count: 1
    assert_select ".invitation-footer", count: 0
    assert_select "input[name='rsvp[adult_names][]'][value=?]", @invitation.full_name
    assert_not_includes response.body, @invitation.note
    assert_not_includes response.body, "placeholder.svg"
  end

  test "an unknown token is not accessible" do
    get invitation_path("token-koji-ne-postoji")

    assert_response :not_found
  end

  test "attending response stores every named adult and child" do
    assert_difference -> { Rsvp.count }, 1 do
      assert_difference -> { RsvpGuest.count }, 3 do
        post invitation_rsvp_path(@invitation.access_token), params: {
          rsvp: {
            attendance: "attending",
            adult_count: "2",
            child_count: "1",
            adult_names: [ "  Milica   Jovanović ", "Nikola Jovanović" ],
            child_names: [ "Lena Jovanović" ],
            message: "Jedva čekamo!"
          }
        }
      end
    end

    assert_redirected_to invitation_path(token: @invitation.access_token, anchor: "rsvp")
    rsvp = @invitation.reload.rsvp
    assert rsvp.attending?
    assert_equal [ "Milica Jovanović", "Nikola Jovanović" ], rsvp.adult_names
    assert_equal [ "Lena Jovanović" ], rsvp.child_names
    assert_equal "Jedva čekamo!", rsvp.message
    assert rsvp.submitted_at.present?
  end

  test "the same personal link edits rather than duplicates a response" do
    post_attending_response
    original_rsvp = @invitation.reload.rsvp

    assert_no_difference -> { Rsvp.count } do
      patch invitation_rsvp_path(@invitation.access_token), params: {
        rsvp: {
          attendance: "attending",
          adult_count: "1",
          child_count: "1",
          adult_names: [ "Milica Jovanović" ],
          child_names: [ "Teodora Jovanović" ],
          message: "Promenjen odgovor"
        }
      }
    end

    assert_redirected_to invitation_path(token: @invitation.access_token, anchor: "rsvp")
    updated_rsvp = @invitation.reload.rsvp
    assert_equal original_rsvp.id, updated_rsvp.id
    assert_equal [ "Milica Jovanović" ], updated_rsvp.adult_names
    assert_equal [ "Teodora Jovanović" ], updated_rsvp.child_names
  end

  test "declining clears a previously submitted guest list" do
    post_attending_response
    assert_equal 2, @invitation.reload.rsvp.rsvp_guests.count

    patch invitation_rsvp_path(@invitation.access_token), params: {
      rsvp: {
        attendance: "declined",
        adult_count: "20",
        child_count: "19",
        adult_names: [ "Tampered Adult" ],
        child_names: [ "Tampered Child" ],
        message: "Nažalost smo sprečeni."
      }
    }

    assert_redirected_to invitation_path(token: @invitation.access_token, anchor: "rsvp")
    rsvp = @invitation.reload.rsvp
    assert rsvp.declined?
    assert_empty rsvp.rsvp_guests
  end

  test "server rejects missing names even when counts were submitted" do
    assert_no_difference -> { Rsvp.count } do
      assert_no_difference -> { RsvpGuest.count } do
        post invitation_rsvp_path(@invitation.access_token), params: {
          rsvp: {
            attendance: "attending",
            adult_count: "2",
            child_count: "1",
            adult_names: [ "Milica Jovanović", "" ],
            child_names: [],
            message: ""
          }
        }
      end
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /ime i prezime/i
  end

  test "server rejects more than twenty guests" do
    adult_names = 20.times.map { |index| "Gost Prezime#{index}" }

    assert_no_difference -> { Rsvp.count } do
      post invitation_rsvp_path(@invitation.access_token), params: {
        rsvp: {
          attendance: "attending",
          adult_count: "20",
          child_count: "1",
          adult_names: adult_names,
          child_names: [ "Dete Prezime" ]
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /najviše 20 gostiju ukupno/i
  end

  private

  def post_attending_response
    post invitation_rsvp_path(@invitation.access_token), params: {
      rsvp: {
        attendance: "attending",
        adult_count: "1",
        child_count: "1",
        adult_names: [ "Milica Jovanović" ],
        child_names: [ "Lena Jovanović" ],
        message: ""
      }
    }
  end
end
