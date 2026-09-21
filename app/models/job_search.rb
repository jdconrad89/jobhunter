class JobSearch < ApplicationRecord
  # Synthetic search used only to group manually added job posts (web form / extension).
  MANUAL_JOB_SEARCH_TITLE = "Manual Job Entries"

  # Matches SerpAPI Google Jobs `apply_options` title strings (e.g. "LinkedIn", "Indeed").
  BOARD_RELEVANCE_ENTRY_MAX_LENGTH = 255

  # Scheduled runs are dispatched every 15 minutes; runtimes must align to that grid.
  RUNTIME_INCREMENT_MINUTES = 15
  RUNTIME_HOURS = (1..12).to_a.freeze
  RUNTIME_MINUTES = [ 0, 15, 30, 45 ].freeze
  RUNTIME_MERIDIEMS = %w[AM PM].freeze

  # TODO: Support non-US timezones (and optionally the fuller ActiveSupport::TimeZone.us_zones list).
  US_TIMEZONES = [
    "Hawaii",
    "Alaska",
    "Pacific Time (US & Canada)",
    "Arizona",
    "Mountain Time (US & Canada)",
    "Central Time (US & Canada)",
    "Eastern Time (US & Canada)",
    "Indiana (East)"
  ].freeze
  DEFAULT_TIMEZONE = "Eastern Time (US & Canada)"

  belongs_to :user
  has_many :job_posts, dependent: :destroy

  # Form-only parts for the daily run time dropdowns (not persisted columns).
  attr_writer :runtime_hour, :runtime_minute, :runtime_meridiem

  validates :job_title, presence: true
  validates :language_code, presence: true
  validates :language_code, format: { with: /\A[a-z]{2}(-[A-Z]{2})?\z/, message: "must be a valid language code (e.g., 'en' or 'en-US')" }, allow_nil: true
  validates :timezone, inclusion: { in: US_TIMEZONES }
  validate :board_relevance_entries_valid, if: -> { board_relevance.present? }
  validate :runtime_on_fifteen_minute_increment, if: -> { runtime.present? }

  before_validation :set_default_timezone
  before_validation :apply_runtime_from_parts
  before_validation :normalize_runtime

  scope :schedulable, -> {
    where.not(runtime: nil).where.not(job_title: MANUAL_JOB_SEARCH_TITLE)
  }

  def update_number_of_jobs!
    update_column(:number_of_jobs, job_posts.count)
  end

  def manual?
    job_title == MANUAL_JOB_SEARCH_TITLE
  end

  # True when +at+, interpreted in this search's timezone and floored to the
  # 15-minute dispatch grid, matches the configured daily runtime (hour + minute).
  def due_at?(at = Time.current)
    return false if runtime.blank? || manual?

    local = at.in_time_zone(timezone)
    slot_minute = (local.min / RUNTIME_INCREMENT_MINUTES) * RUNTIME_INCREMENT_MINUTES

    runtime.hour == local.hour && runtime.min == slot_minute
  end

  def self.due_for_run(at = Time.current)
    schedulable.select { |job_search| job_search.due_at?(at) }
  end

  # Build a Time-of-day from 12-hour form parts. Returns nil when all blank,
  # false when incomplete/invalid (caller should treat as a validation error).
  def self.compose_runtime(hour:, minute:, meridiem:)
    hour_s = hour.to_s.strip
    minute_s = minute.to_s.strip
    meridiem_s = meridiem.to_s.strip.upcase

    return nil if hour_s.blank? && minute_s.blank? && meridiem_s.blank?
    return false if hour_s.blank? || minute_s.blank? || meridiem_s.blank?

    hour_i = hour_s.to_i
    minute_i = minute_s.to_i
    return false unless RUNTIME_HOURS.include?(hour_i)
    return false unless RUNTIME_MINUTES.include?(minute_i)
    return false unless RUNTIME_MERIDIEMS.include?(meridiem_s)

    hour24 = if meridiem_s == "AM"
      hour_i == 12 ? 0 : hour_i
    else
      hour_i == 12 ? 12 : hour_i + 12
    end

    Time.zone.local(2000, 1, 1, hour24, minute_i)
  end

  def runtime_hour
    return @runtime_hour if instance_variable_defined?(:@runtime_hour)
    return if runtime.blank?

    ((runtime.hour + 11) % 12) + 1
  end

  def runtime_minute
    return @runtime_minute if instance_variable_defined?(:@runtime_minute)
    return if runtime.blank?

    runtime.min
  end

  def runtime_meridiem
    return @runtime_meridiem if instance_variable_defined?(:@runtime_meridiem)
    return if runtime.blank?

    runtime.hour < 12 ? "AM" : "PM"
  end

  private

  def set_default_timezone
    return if timezone.present?

    self.timezone = US_TIMEZONES.include?(Time.zone.name) ? Time.zone.name : DEFAULT_TIMEZONE
  end

  def runtime_parts_submitted?
    instance_variable_defined?(:@runtime_hour) ||
      instance_variable_defined?(:@runtime_minute) ||
      instance_variable_defined?(:@runtime_meridiem)
  end

  def apply_runtime_from_parts
    return unless runtime_parts_submitted?

    composed = self.class.compose_runtime(
      hour: @runtime_hour,
      minute: @runtime_minute,
      meridiem: @runtime_meridiem
    )

    if composed == false
      errors.add(:runtime, "must include hour, minutes, and AM/PM")
      return
    end

    self.runtime = composed
  end

  def normalize_runtime
    return if runtime.blank?

    self.runtime = runtime.change(sec: 0, usec: 0)
  end

  def runtime_on_fifteen_minute_increment
    return if (runtime.min % RUNTIME_INCREMENT_MINUTES).zero?

    errors.add(:runtime, "must be in #{RUNTIME_INCREMENT_MINUTES}-minute increments (e.g. 9:00, 9:15, 9:30, 9:45)")
  end

  def board_relevance_entries_valid
    unless board_relevance.is_a?(Array)
      errors.add(:board_relevance, "must be a list of job board names")
      return
    end

    board_relevance.each do |entry|
      unless entry.is_a?(String)
        errors.add(:board_relevance, "must contain only text values")
        break
      end

      name = entry.strip
      if name.blank?
        errors.add(:board_relevance, "cannot include blank entries")
        break
      end

      if name.length > BOARD_RELEVANCE_ENTRY_MAX_LENGTH
        errors.add(:board_relevance, "each name must be #{BOARD_RELEVANCE_ENTRY_MAX_LENGTH} characters or fewer")
        break
      end
    end
  end
end
