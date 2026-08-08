class Rsvp < ApplicationRecord
  MAX_GUESTS = 20

  belongs_to :invitation
  has_many :rsvp_guests,
    -> { order(:position, :id) },
    dependent: :destroy,
    inverse_of: :rsvp,
    autosave: true

  enum :attendance, { attending: "attending", declined: "declined" }, validate: true

  validates :invitation_id, uniqueness: true
  validates :attendance, :submitted_at, presence: true
  validates :message, length: { maximum: 2_000 }
  validates_associated :rsvp_guests
  validate :attending_guest_requirements

  before_validation :discard_guests_when_declined

  def replace_guest_names(adult_names:, child_names:)
    rsvp_guests.each(&:mark_for_destruction)

    position = 0
    {
      adult: Array(adult_names),
      child_under_10: Array(child_names)
    }.each do |guest_type, names|
      names.each do |name|
        rsvp_guests.build(
          full_name: name.to_s.squish,
          guest_type: guest_type,
          position: position
        )
        position += 1
      end
    end

    self
  end

  def adult_count
    active_guests.count(&:adult?)
  end

  def child_count
    active_guests.count(&:child_under_10?)
  end

  def adult_names
    active_guests.select(&:adult?).map(&:full_name)
  end

  def child_names
    active_guests.select(&:child_under_10?).map(&:full_name)
  end

  private

  def active_guests
    rsvp_guests.reject(&:marked_for_destruction?)
  end

  def discard_guests_when_declined
    return unless declined?

    rsvp_guests.each(&:mark_for_destruction)
  end

  def attending_guest_requirements
    return unless attending?

    guests = active_guests
    errors.add(:rsvp_guests, "moraju sadržati bar jednu osobu") if guests.empty?
    errors.add(:rsvp_guests, "ne mogu sadržati više od #{MAX_GUESTS} osoba") if guests.size > MAX_GUESTS
  end
end
