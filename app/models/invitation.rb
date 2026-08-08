class Invitation < ApplicationRecord
  has_secure_token :access_token, length: 32

  has_one :rsvp, dependent: :destroy

  normalizes :first_name, :last_name, with: ->(name) { name.to_s.squish }

  validates :first_name, :last_name, presence: true, length: { maximum: 80 }
  validates :access_token, presence: true, uniqueness: true
  validates :note, length: { maximum: 500 }

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
