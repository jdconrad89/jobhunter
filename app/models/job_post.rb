class JobPost < ApplicationRecord
  include JobPost::DescriptionEnrichment
  include JobPost::SimilarListings

  belongs_to :company
  belongs_to :job_search
  has_many :job_applications, dependent: :destroy

  validates :title, presence: true
  validates :website, presence: true

  before_validation :set_default_posted_at, on: :create
  before_save :populate_pay_range_numbers
  before_save :populate_experience_years
  after_save :update_job_search_jobs_count
  after_destroy :update_job_search_jobs_count

  scope :remote_only, -> { where(remote: true) }
  scope :on_site_only, -> { where(remote: false) }
  scope :contract_only, -> { where("job_posts.title ILIKE ? OR job_posts.description ILIKE ?", "%contract%", "%contract%") }
  scope :full_time_only, -> { where("COALESCE(job_posts.title, '') NOT ILIKE ? AND COALESCE(job_posts.description, '') NOT ILIKE ?", "%contract%", "%contract%") }
  scope :filter_by_pay_range, ->(min_salary, max_salary) {
    scope = all
    scope = scope.where("pay_range_max >= ?", min_salary) if min_salary.present?
    scope = scope.where("pay_range_min <= ?", max_salary) if max_salary.present?
    scope
  }
  scope :filter_by_experience_range, ->(min_years, max_years) {
    scope = all
    scope = scope.where("experience_years_max >= ?", min_years) if min_years.present?
    scope = scope.where("experience_years_min <= ?", max_years) if max_years.present?
    scope
  }

  def self.filtered(params)
    JobPosts::Filter.call(params)
  end

  def update_job_search_jobs_count
    job_search&.update_number_of_jobs!
  end

  def populate_pay_range_numbers
    min_max = parse_pay_range_numbers
    if min_max
      self.pay_range_min = min_max[0]
      self.pay_range_max = min_max[1]
    else
      self.pay_range_min = nil
      self.pay_range_max = nil
    end
  end

  def populate_experience_years
    min_max = parse_experience_years
    if min_max
      self.experience_years_min = min_max[0]
      self.experience_years_max = min_max[1]
    else
      self.experience_years_min = nil
      self.experience_years_max = nil
    end
  end

  def set_default_posted_at
    self.posted_at ||= Time.current
  end
end
