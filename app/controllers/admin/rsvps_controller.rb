require "csv"

module Admin
  class RsvpsController < BaseController
    before_action :set_invitation, except: :export
    before_action :set_rsvp, except: :export

    def edit
      prepare_guest_form
    end

    def create
      submit_response
    end

    def update
      submit_response
    end

    def export
      invitations = Invitation.includes(rsvp: :rsvp_guests).order(:last_name, :first_name)

      csv = CSV.generate(headers: true) do |rows|
        rows << [
          "Pozivnica za",
          "Status",
          "Ime gosta",
          "Kategorija gosta",
          "Poruka",
          "Odgovoreno",
          "Napomena",
          "Link"
        ]

        invitations.each do |invitation|
          append_invitation_rows(rows, invitation)
        end
      end

      send_data "\uFEFF#{csv}",
        filename: "odgovori-#{Time.zone.today.iso8601}.csv",
        type: "text/csv; charset=utf-8",
        disposition: "attachment"
    end

    private

    def set_invitation
      @invitation = Invitation.includes(rsvp: :rsvp_guests).find(params[:invitation_id])
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
        redirect_to admin_invitation_path(@invitation), notice: "Odgovor je sačuvan ručno."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def prepare_guest_form
      @adult_names = @rsvp.adult_names
      @child_names = @rsvp.child_names
      @adult_names = [ @invitation.full_name ] if @rsvp.new_record? && @adult_names.empty?
      @adult_count = @rsvp.attending? ? [ @adult_names.length, 1 ].max : 1
      @child_count = @rsvp.attending? ? @child_names.length : 0
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

    def append_invitation_rows(rows, invitation)
      rsvp = invitation.rsvp
      guests = rsvp&.rsvp_guests&.sort_by(&:position) || []

      if guests.any?
        guests.each { |guest| rows << csv_row(invitation, rsvp, guest) }
      else
        # Keep declined, pending and malformed/empty attending responses visible in the export.
        rows << csv_row(invitation, rsvp, nil)
      end
    end

    def csv_row(invitation, rsvp, guest)
      [
        invitation_display_name(invitation),
        invitation_status_label(invitation),
        guest&.full_name,
        guest && guest_type_label(guest),
        rsvp&.message,
        rsvp&.submitted_at&.in_time_zone&.strftime("%d.%m.%Y. %H:%M"),
        invitation.note,
        invitation_url(invitation.access_token)
      ]
    end
  end
end
