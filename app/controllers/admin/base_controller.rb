module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_admin

    helper_method :current_admin_user,
      :invitation_display_name,
      :invitation_status,
      :invitation_status_label,
      :guest_type_label

    private

    def current_admin_user
      @current_admin_user ||= User.find_by(id: session[:admin_user_id])
    end

    def require_admin
      return if current_admin_user

      redirect_to admin_login_path, alert: "Prijavite se da biste otvorili administraciju."
    end

    def invitation_display_name(invitation)
      [ invitation.first_name, invitation.last_name ].compact_blank.join(" ")
    end

    def invitation_status(invitation)
      case invitation.rsvp&.attendance
      when "attending" then "attending"
      when "declined" then "declined"
      else "pending"
      end
    end

    def invitation_status_label(invitation)
      {
        "attending" => "Dolaze",
        "declined" => "Ne dolaze",
        "pending" => "Čeka se odgovor"
      }.fetch(invitation_status(invitation))
    end

    def guest_type_label(guest)
      guest.guest_type == "child_under_10" ? "Dete mlađe od 10 godina" : "Odrasla osoba"
    end
  end
end
