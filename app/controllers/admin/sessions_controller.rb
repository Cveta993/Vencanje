module Admin
  class SessionsController < BaseController
    skip_before_action :require_admin, only: %i[new create]

    def new
      redirect_to admin_root_path if current_admin_user
    end

    def create
      user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

      if user&.authenticate(params[:password])
        reset_session
        session[:admin_user_id] = user.id
        redirect_to admin_root_path, notice: "Uspešno ste se prijavili."
      else
        flash.now[:alert] = "Email adresa ili lozinka nisu ispravni."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to admin_login_path, notice: "Uspešno ste se odjavili."
    end
  end
end
