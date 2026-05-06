class JobSearch < ApplicationRecord
  # Matches SerpAPI Google Jobs `apply_options` title strings (e.g. "LinkedIn", "Indeed").
  BOARD_RELEVANCE_ENTRY_MAX_LENGTH = 255

  belongs_to :user
  has_many :job_posts, dependent: :destroy

  validates :job_title, presence: true
  validates :language_code, presence: true
  validates :language_code, format: { with: /\A[a-z]{2}(-[A-Z]{2})?\z/, message: "must be a valid language code (e.g., 'en' or 'en-US')" }, allow_nil: true
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validate :board_relevance_entries_valid, if: -> { board_relevance.present? }

  before_validation :set_default_timezone

  def runtime_in_timezone
    return nil unless runtime && timezone
    runtime.in_time_zone(timezone)
  end

  def update_number_of_jobs!
    update_column(:number_of_jobs, job_posts.count)
  end

  def next_run_time
    return nil unless runtime && timezone
    now = Time.current.in_time_zone(timezone)
    today_run = now.change(
      hour: runtime.hour,
      min: runtime.min,
      sec: 0
    )

    if today_run > now
      today_run
    else
      today_run + 1.day
    end
  end

  private

  def set_default_timezone
    self.timezone ||= Time.zone.name
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
