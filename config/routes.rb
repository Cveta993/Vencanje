Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "welcome#show"

  get "pozivnica/:token", to: "invitations#show", as: :invitation
  post "pozivnica/:token/rsvp", to: "rsvps#create", as: :invitation_rsvp
  patch "pozivnica/:token/rsvp", to: "rsvps#update"

  namespace :admin do
    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout

    root "invitations#index"

    resources :invitations, only: %i[index new create show edit update destroy] do
      post :regenerate_link, on: :member
      resource :rsvp, only: %i[edit create update], controller: :rsvps
    end

    get "rsvps/export", to: "rsvps#export", as: :rsvps_export, defaults: { format: :csv }
  end
end
