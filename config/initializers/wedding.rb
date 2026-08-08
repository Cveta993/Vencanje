wedding_configuration = Rails.application.config_for(:wedding).deep_symbolize_keys
Rails.application.config.x.wedding = wedding_configuration.freeze
