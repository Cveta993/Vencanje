class RsvpSubmission
  MAX_GUESTS = Rsvp::MAX_GUESTS
  MAX_NAME_LENGTH = 120
  MAX_MESSAGE_LENGTH = 2_000
  ATTENDANCE_OPTIONS = %w[attending declined].freeze

  attr_reader :adult_count, :adult_names, :child_count, :child_names, :rsvp

  def initialize(rsvp:, params:)
    @rsvp = rsvp
    @params = params
    @persisted_before_submission = rsvp.persisted?

    @attendance = params[:attendance].to_s
    @adult_names = normalize_names(params[:adult_names])
    @child_names = normalize_names(params[:child_names])
    @adult_count = parse_count(params[:adult_count])
    @child_count = parse_count(params[:child_count])
  end

  def submit
    rsvp.assign_attributes(attendance: @attendance, message: normalize_message(@params[:message]))
    validate_submission
    return false if rsvp.errors.any?

    rsvp.transaction do
      rsvp.replace_guest_names(
        adult_names: rsvp.declined? ? [] : adult_names,
        child_names: rsvp.declined? ? [] : child_names
      )
      rsvp.submitted_at = Time.current
      rsvp.save!
    end

    @submitted = true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def created?
    @submitted && !@persisted_before_submission
  end

  private

  def validate_submission
    unless ATTENDANCE_OPTIONS.include?(@attendance)
      rsvp.errors.add(:attendance, "izaberite da li dolazite")
      return
    end

    if rsvp.message.to_s.length > MAX_MESSAGE_LENGTH
      rsvp.errors.add(:message, "može imati najviše #{MAX_MESSAGE_LENGTH} karaktera")
    end

    return if @attendance == "declined"

    validate_counts
    validate_names(adult_names, "odraslog gosta")
    validate_names(child_names, "deteta")
  end

  def validate_counts
    if adult_count.nil? || adult_count < 1
      rsvp.errors.add(:base, "Izaberite broj odraslih gostiju.")
    elsif adult_count > MAX_GUESTS
      rsvp.errors.add(:base, "Možete prijaviti najviše #{MAX_GUESTS} gostiju.")
    end

    if child_count.nil? || child_count.negative?
      rsvp.errors.add(:base, "Izaberite broj dece mlađe od 10 godina.")
    end

    if adult_count && child_count && adult_count + child_count > MAX_GUESTS
      rsvp.errors.add(:base, "Možete prijaviti najviše #{MAX_GUESTS} gostiju ukupno.")
    end

    if adult_count && adult_names.length != adult_count
      rsvp.errors.add(:base, "Unesite ime i prezime za svakog odraslog gosta.")
    end

    if child_count && child_names.length != child_count
      rsvp.errors.add(:base, "Unesite ime i prezime za svako dete.")
    end
  end

  def validate_names(names, guest_label)
    names.each do |name|
      if name.blank?
        rsvp.errors.add(:base, "Unesite ime i prezime svakog #{guest_label}.")
      elsif name.length > MAX_NAME_LENGTH
        rsvp.errors.add(:base, "Ime #{guest_label} može imati najviše #{MAX_NAME_LENGTH} karaktera.")
      elsif name.split.size < 2
        rsvp.errors.add(:base, "Unesite i ime i prezime za svakog #{guest_label}.")
      end
    end
  end

  def normalize_names(names)
    Array(names).map { |name| name.to_s.squish }
  end

  def normalize_message(message)
    message.to_s.strip.presence
  end

  def parse_count(value)
    Integer(value, 10)
  rescue ArgumentError, TypeError
    nil
  end
end
