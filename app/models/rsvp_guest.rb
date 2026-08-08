class RsvpGuest < ApplicationRecord
  belongs_to :rsvp, inverse_of: :rsvp_guests

  enum :guest_type, { adult: "adult", child_under_10: "child_under_10" }, validate: true

  normalizes :full_name, with: ->(name) { name.to_s.squish }

  validates :full_name, presence: true, length: { maximum: 120 }
  validates :guest_type, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
