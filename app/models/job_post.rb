class JobPost < ApplicationRecord
  belongs_to :company
  belongs_to :job_search
  has_many :job_applications, dependent: :destroy

  validates :title, presence: true
  validates :website, presence: true

  # Regex patterns for pay range extraction (order matters - more specific first)
  # Using %r{} to avoid / delimiter conflicts (e.g. /yr in pattern)
  PAY_RANGE_PATTERNS = [
    # $120,000 - $160,000 or $120k - $160k (with optional "per year", "annually", etc.)
    %r{\$[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*\$[\d,]+(?:\.\d{2})?(?:k|K)?(?:\s*(?:per year|yearly|annually|/yr|a year))?}i,
    # £50,000 - £75,000
    %r{£[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*£[\d,]+(?:\.\d{2})?(?:k|K)?(?:\s*(?:per year|yearly|annually))?}i,
    # €50,000 - €75,000
    %r{€[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*€[\d,]+(?:\.\d{2})?(?:k|K)?(?:\s*(?:per year|yearly|annually))?}i,
    # USD 120,000 - 160,000
    %r{USD\s*[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*[\d,]+(?:\.\d{2})?(?:k|K)?}i,
    # Salary: $X - $Y or Compensation: $X - $Y
    %r{(?:salary|compensation|pay)\s*(?:range)?\s*:?\s*\$[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*\$[\d,]+(?:\.\d{2})?(?:k|K)?}im
  ].freeze

  EXPERIENCE_RANGE_PATTERNS = [
    # "3+ years", "3 years", "3 yrs"
    %r{(\d{1,2})\s*\+?\s*(?:years?|yrs?)\s+(?:of\s+)?experience}i,
    # "minimum 3 years", "at least 3 years"
    %r{(?:minimum|min\.?|at\s+least)\s*(\d{1,2})\s*(?:\+?\s*)?(?:years?|yrs?)}i,
    # "3-5 years", "3 to 5 years"
    %r{(\d{1,2})\s*(?:-|to)\s*(\d{1,2})\s*(?:years?|yrs?)}i
  ].freeze

  NUMBER_WORDS = {
    "one" => 1,
    "two" => 2,
    "three" => 3,
    "four" => 4,
    "five" => 5,
    "six" => 6,
    "seven" => 7,
    "eight" => 8,
    "nine" => 9,
    "ten" => 10,
    "eleven" => 11,
    "twelve" => 12,
    "thirteen" => 13,
    "fourteen" => 14,
    "fifteen" => 15,
    "sixteen" => 16,
    "seventeen" => 17,
    "eighteen" => 18,
    "nineteen" => 19,
    "twenty" => 20
  }.freeze

  SKILL_PATTERNS = {
    "Ruby on Rails" => %r{\bruby\s+on\s+rails\b}i,
    "Ruby" => %r{\bruby\b}i,
    "Python" => %r{\bpython\b}i,
    "Django" => %r{\bdjango\b}i,
    "JavaScript" => %r{\bjavascript\b|\bjs\b}i,
    "TypeScript" => %r{\btypescript\b|\bts\b}i,
    "React" => %r{\breact\b}i,
    "Node.js" => %r{\bnode(?:\.js)?\b}i,
    "AI/ML" => %r{\bai\b|\bmachine\s+learning\b|\bml\b|\bartificial\s+intelligence\b}i,
    "TDD" => %r{\btdd\b|\btest[-\s]?driven\b}i,
    "RSpec" => %r{\brspec\b}i,
    "AWS" => %r{\baws\b|\bamazon\s+web\s+services\b}i,
    "Azure" => %r{\bazure\b}i,
    "GCP" => %r{\bgcp\b|\bgoogle\s+cloud\b}i,
    "Docker" => %r{\bdocker\b}i,
    "Kubernetes" => %r{\bkubernetes\b|\bk8s\b}i,
    "PostgreSQL" => %r{\bpostgres(?:ql)?\b}i,
    "MySQL" => %r{\bmysql\b}i,
    "Redis" => %r{\bredis\b}i,
    "GraphQL" => %r{\bgraphql\b}i,
    "REST API" => %r{\brest(?:ful)?\b|\bapi\b}i
  }.freeze

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

  # Builds the filtered relation used by the Job Posts index.
  # Keep controller logic thin as we add more filter options.
  def self.filtered(params)
    scope = includes(:company).order(created_at: :desc)

    if (company = params[:company].to_s.strip).present?
      escaped_company = ActiveRecord::Base.sanitize_sql_like(company)
      scope = scope.joins(:company).where("companies.name ILIKE ?", "%#{escaped_company}%")
    end

    case params[:remote]
    when "true"
      scope = scope.remote_only
    when "false"
      scope = scope.on_site_only
    end

    case params[:position_type]
    when "contract"
      scope = scope.contract_only
    when "full_time"
      scope = scope.full_time_only
    end

    # Pay range filter (format: "min_max" or "min_" for open-ended)
    if params[:pay_range].present?
      parts = params[:pay_range].split("_")
      pay_min = parts[0].presence&.to_i
      pay_max = parts[1].presence&.to_i if parts[1].present?
      scope = scope.filter_by_pay_range(pay_min, pay_max) if pay_min.present? || pay_max.present?
    end

    # Experience range filter (format: "min_max" or "min_" for open-ended)
    if params[:experience_range].present?
      parts = params[:experience_range].split("_")
      exp_min = parts[0].presence&.to_i
      exp_max = parts[1].presence&.to_i if parts[1].present?
      scope = scope.filter_by_experience_range(exp_min, exp_max) if exp_min.present? || exp_max.present?
    end

    scope
  end

  def extract_pay_range
    return nil if description.blank?

    text = description.is_a?(String) ? description : description.to_s
    PAY_RANGE_PATTERNS.each do |pattern|
      match = text.match(pattern)
      return match[0].strip if match
    end
    nil
  end

  def parse_pay_range_numbers
    range_str = extract_pay_range
    return nil if range_str.blank?

    # Extract numbers: "120,000", "160k", "120k", etc.
    numbers = range_str.scan(%r{[\d,]+(?:\.\d{2})?(?:k|K)?}).map do |num_str|
      num_str = num_str.gsub(",", "")
      multiplier = (num_str =~ /k$/i) ? 1000 : 1
      value = num_str.gsub(/k$/i, "").to_f
      (value * multiplier).to_i
    end
    numbers.size >= 2 ? [numbers.min, numbers.max] : nil
  end

  def extract_experience_requirement
    return nil if description.blank?

    text = description.is_a?(String) ? description : description.to_s

    # Prefer range match first for richer information
    range_match = text.match(EXPERIENCE_RANGE_PATTERNS[2])
    return "#{range_match[1]}-#{range_match[2]} years" if range_match

    EXPERIENCE_RANGE_PATTERNS[0..1].each do |pattern|
      match = text.match(pattern)
      return "#{match[1]}+ years" if match
    end

    word_based = extract_word_based_experience(text)
    return word_based if word_based.present?

    nil
  end

  def parse_experience_years
    requirement = extract_experience_requirement
    return nil if requirement.blank?

    if (match = requirement.match(/(\d{1,2})-(\d{1,2})/))
      [match[1].to_i, match[2].to_i]
    elsif (match = requirement.match(/(\d{1,2})\+/))
      [match[1].to_i, match[1].to_i]
    else
      nil
    end
  end

  def extract_word_based_experience(text)
    return nil if text.blank?

    words_pattern = NUMBER_WORDS.keys.join("|")

    # "three to five years experience", "four-five years", etc.
    range_regex = %r{(#{words_pattern})\s*(?:-|to)\s*(#{words_pattern})\s*(?:years?|yrs?)(?:\s+of\s+experience|\s+experience)?}i
    if (range_match = text.match(range_regex))
      min = number_word_to_i(range_match[1])
      max = number_word_to_i(range_match[2])
      return "#{min}-#{max} years" if min && max
    end

    # "at least three years", "minimum four years", "three years of experience"
    single_regex = %r{(?:(?:minimum|min\.?|at\s+least)\s+)?(#{words_pattern})\s*(?:\+?\s*)?(?:years?|yrs?)(?:\s+of\s+experience|\s+experience)?}i
    if (single_match = text.match(single_regex))
      value = number_word_to_i(single_match[1])
      return "#{value}+ years" if value
    end

    nil
  end

  def number_word_to_i(word)
    NUMBER_WORDS[word.to_s.downcase]
  end

  def contract?
    return false if title.blank? && description.blank?

    text = [title, description].compact.join(" ")
    %w[contract contractor contract position].any? { |term| text.downcase.include?(term) }
  end

  def extracted_skills
    text = [title, description].compact.join(" ")
    return [] if text.blank?

    SKILL_PATTERNS.each_with_object([]) do |(skill, pattern), found|
      found << skill if text.match?(pattern)
    end
  end

  def suggested_jobs(limit: 4, candidate_pool: 250)
    base_skills = extracted_skills
    return [] if base_skills.empty?

    candidates = JobPost
      .includes(:company)
      .where.not(id: id)
      .order(created_at: :desc)
      .limit(candidate_pool)

    ranked = candidates.filter_map do |candidate|
      overlap = candidate.extracted_skills & base_skills
      next if overlap.empty?

      [
        candidate,
        overlap.length,
        overlap
      ]
    end

    ranked
      .sort_by { |_post, score, _overlap| -score }
      .first(limit)
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

  def description_with_highlighted_pay
    return "" if description.blank?

    formatted = ActionController::Base.helpers.simple_format(description)
    pay_range = extract_pay_range
    return formatted if pay_range.blank?

    # Escape for use in regex, wrap in highlight span
    escaped = Regexp.escape(pay_range)
    formatted.gsub(Regexp.new("(#{escaped})"), '<span class="pay-range-highlight">\1</span>')
  end

  def set_default_posted_at
    self.posted_at ||= Time.current
  end
end 