module WeddingHelper
  def wedding_config
    Rails.configuration.x.wedding
  end

  def wedding_couple_names
    wedding_config.dig(:couple, :names)
  end

  def wedding_image(slot)
    wedding_config.dig(:images, slot)
  end

  def wedding_events
    wedding_config.fetch(:events)
  end

  def invitation_recipient_name
    @invitation.full_name
  end

  def rsvp_form_url
    invitation_rsvp_path(token: @invitation.access_token)
  end

  def rsvp_form_method
    @rsvp.persisted? ? :patch : :post
  end
end
