class RsvpsController < ApplicationController
  before_action :set_invitation
  before_action :set_rsvp

  def create
    submit_response
  end

  def update
    submit_response
  end

  private

  def set_invitation
    @invitation = Invitation.find_by!(access_token: params[:token])
  end

  def set_rsvp
    @rsvp = @invitation.rsvp || @invitation.build_rsvp
  end

  def submit_response
    submission = RsvpSubmission.new(rsvp: @rsvp, params: rsvp_params)
    @adult_count = submission.adult_count
    @child_count = submission.child_count
    @adult_names = submission.adult_names
    @child_names = submission.child_names

    if submission.submit
      redirect_to invitation_path(token: @invitation.access_token, anchor: "rsvp"),
        notice: submission.created? ? "Hvala, sačuvali smo vaš odgovor." : "Hvala, izmenili smo vaš odgovor."
    else
      render "invitations/show", status: :unprocessable_entity
    end
  end

  def rsvp_params
    params.require(:rsvp).permit(
      :attendance,
      :adult_count,
      :child_count,
      :message,
      adult_names: [],
      child_names: []
    )
  end
end
