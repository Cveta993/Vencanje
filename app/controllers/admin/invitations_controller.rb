module Admin
  class InvitationsController < BaseController
    before_action :set_invitation, only: %i[show edit update destroy regenerate_link]

    def index
      all_invitations = Invitation.includes(rsvp: :rsvp_guests).order(:last_name, :first_name).to_a

      @summary = {
        invitations: all_invitations.size,
        attending: all_invitations.count { |invitation| invitation_status(invitation) == "attending" },
        declined: all_invitations.count { |invitation| invitation_status(invitation) == "declined" },
        pending: all_invitations.count { |invitation| invitation_status(invitation) == "pending" },
        adults: all_invitations.sum { |invitation| invitation.rsvp&.adult_count.to_i },
        children: all_invitations.sum { |invitation| invitation.rsvp&.child_count.to_i }
      }

      @invitations = filter_invitations(all_invitations)
    end

    def show
    end

    def new
      @invitation = Invitation.new
    end

    def create
      @invitation = Invitation.new(invitation_params)

      if @invitation.save
        redirect_to admin_invitation_path(@invitation), notice: "Pozivnica je kreirana. Link je spreman za slanje."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @invitation.update(invitation_params)
        redirect_to admin_invitation_path(@invitation), notice: "Pozivnica je sačuvana."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      invitation_name = invitation_display_name(@invitation)
      @invitation.destroy!

      redirect_to admin_invitations_path,
        notice: "Pozivnica za #{invitation_name}, njen odgovor i imena gostiju su obrisani.",
        status: :see_other
    end

    def regenerate_link
      @invitation.regenerate_access_token
      redirect_to admin_invitation_path(@invitation), notice: "Kreiran je novi link. Prethodni link više ne radi."
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_invitation_path(@invitation), alert: "Novi link nije mogao da se kreira."
    end

    private

    def set_invitation
      @invitation = Invitation.includes(rsvp: :rsvp_guests).find(params[:id])
    end

    def invitation_params
      params.require(:invitation).permit(:first_name, :last_name, :note)
    end

    def filter_invitations(invitations)
      filtered = invitations

      if params[:status].present? && %w[attending declined pending].include?(params[:status])
        filtered = filtered.select { |invitation| invitation_status(invitation) == params[:status] }
      end

      if params[:q].present?
        query = params[:q].to_s.strip.downcase
        filtered = filtered.select do |invitation|
          invitation_display_name(invitation).downcase.include?(query)
        end
      end

      filtered
    end
  end
end
