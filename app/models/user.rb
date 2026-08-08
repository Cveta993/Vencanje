class User < ApplicationRecord
  has_secure_password

  normalizes :email_address, with: ->(email) { email.to_s.strip.downcase }

  validates :email_address,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
end
