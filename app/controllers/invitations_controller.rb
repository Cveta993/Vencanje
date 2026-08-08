class InvitationsController < ApplicationController
  before_action :set_invitation

  def show
    @rsvp = @invitation.rsvp || @invitation.build_rsvp
    prepare_guest_form
  end

  private

  def set_invitation
    @invitation = Invitation.find_by!(access_token: params[:token])
  end

  def prepare_guest_form
    adult_guests = @rsvp.rsvp_guests.select { |guest| guest.guest_type == "adult" }
    child_guests = @rsvp.rsvp_guests.select { |guest| guest.guest_type == "child_under_10" }

    @adult_names = adult_guests.sort_by(&:position).map(&:full_name)
    @child_names = child_guests.sort_by(&:position).map(&:full_name)

    # Starting with one adult makes accepting the invitation quick, while the
    # attendance choice itself intentionally remains unanswered.
    @adult_names = [ @invitation.full_name ] if @rsvp.new_record? && @adult_names.empty?
    @adult_count = @rsvp.attending? ? [ @adult_names.length, 1 ].max : 1
    @child_count = @rsvp.attending? ? @child_names.length : 0
  end
end
