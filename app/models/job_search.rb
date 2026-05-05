class JobSearch < ApplicationRecord
  belongs_to :user
  has_many :job_posts, dependent: :destroy

  validates :job_title, presence: true
  validates :language_code, presence: true
  validates :language_code, format: { with: /\A[a-z]{2}(-[A-Z]{2})?\z/, message: "must be a valid language code (e.g., 'en' or 'en-US')" }, allow_nil: true
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validate :board_relevance_is_array_of_urls, if: -> { board_relevance.present? }

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

  def board_relevance_is_array_of_urls
    return if board_relevance.nil? || board_relevance.empty?
    unless board_relevance.is_a?(Array) && board_relevance.all? { |url| valid_url?(url) }
      errors.add(:board_relevance, "must be an array of valid URLs")
    end
  end

  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end
end 