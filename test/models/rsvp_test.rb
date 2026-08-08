require "test_helper"

class RsvpTest < ActiveSupport::TestCase
  setup do
    @invitation = Invitation.create!(first_name: "Ana", last_name: "Petrović")
  end

  test "derives totals and names from attendee rows" do
    rsvp = @invitation.build_rsvp(attendance: :attending, submitted_at: Time.current)
    rsvp.replace_guest_names(
      adult_names: [ "Ana Petrović", "Marko Petrović" ],
      child_names: [ "Mila Petrović" ]
    )

    assert rsvp.save
    assert_equal 2, rsvp.adult_count
    assert_equal 1, rsvp.child_count
    assert_equal [ "Ana Petrović", "Marko Petrović" ], rsvp.adult_names
  end

  test "requires every generated attendee name" do
    rsvp = @invitation.build_rsvp(attendance: :attending, submitted_at: Time.current)
    rsvp.replace_guest_names(adult_names: [ "Ana Petrović", "" ], child_names: [])

    assert_not rsvp.valid?
    assert rsvp.rsvp_guests.second.errors[:full_name].any?
  end

  test "requires at least one attendee when attending" do
    rsvp = @invitation.build_rsvp(attendance: :attending, submitted_at: Time.current)

    assert_not rsvp.valid?
    assert rsvp.errors[:rsvp_guests].any?
  end

  test "rejects more than twenty attendees" do
    rsvp = @invitation.build_rsvp(attendance: :attending, submitted_at: Time.current)
    rsvp.replace_guest_names(adult_names: 21.times.map { |index| "Gost #{index}" }, child_names: [])

    assert_not rsvp.valid?
    assert rsvp.errors[:rsvp_guests].any? { |message| message.include?("20") }
  end

  test "declining removes previously saved attendees" do
    rsvp = @invitation.build_rsvp(attendance: :attending, submitted_at: Time.current)
    rsvp.replace_guest_names(adult_names: [ "Ana Petrović" ], child_names: [])
    rsvp.save!

    rsvp.attendance = :declined
    rsvp.save!

    assert_equal 0, rsvp.reload.rsvp_guests.count
  end
end
