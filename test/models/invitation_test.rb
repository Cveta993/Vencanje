require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "creates a long unique access token and normalizes the recipient name" do
    invitation = Invitation.create!(first_name: "  Ana  Marija ", last_name: " Petrović ")

    assert_equal "Ana Marija Petrović", invitation.full_name
    assert_operator invitation.access_token.length, :>=, 32
  end

  test "requires both parts of the recipient name" do
    invitation = Invitation.new(first_name: "Ana")

    assert_not invitation.valid?
    assert invitation.errors[:last_name].any?
  end
end
