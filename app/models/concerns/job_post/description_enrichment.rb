# frozen_string_literal: true

module JobPost::DescriptionEnrichment
  extend ActiveSupport::Concern

  # Regex patterns for pay range extraction (order matters - more specific first)
  PAY_RANGE_PATTERNS = [
    %r{\$[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*\$[\d,]+(?:\.\d{2})?(?:k|K)?(?:\s*(?:per year|yearly|annually|/yr|a year))?}i,
    %r{£[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*£[\d,]+(?:\.\d{2})?(?:k|K)?(?:\s*(?:per year|yearly|annually))?}i,
    %r{€[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*€[\d,]+(?:\.\d{2})?(?:k|K)?(?:\s*(?:per year|yearly|annually))?}i,
    %r{USD\s*[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*[\d,]+(?:\.\d{2})?(?:k|K)?}i,
    %r{(?:salary|compensation|pay)\s*(?:range)?\s*:?\s*\$[\d,]+(?:\.\d{2})?(?:k|K)?\s*(?:-|–|to)\s*\$[\d,]+(?:\.\d{2})?(?:k|K)?}im
  ].freeze

  EXPERIENCE_RANGE_PATTERNS = [
    %r{(\d{1,2})\s*\+?\s*(?:years?|yrs?)\s+(?:of\s+)?experience}i,
    %r{(?:minimum|min\.?|at\s+least)\s*(\d{1,2})\s*(?:\+?\s*)?(?:years?|yrs?)}i,
    %r{(\d{1,2})\s*(?:-|to)\s*(\d{1,2})\s*(?:years?|yrs?)}i
  ].freeze

  NUMBER_WORDS = {
    "one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5,
    "six" => 6, "seven" => 7, "eight" => 8, "nine" => 9, "ten" => 10,
    "eleven" => 11, "twelve" => 12, "thirteen" => 13, "fourteen" => 14,
    "fifteen" => 15, "sixteen" => 16, "seventeen" => 17, "eighteen" => 18,
    "nineteen" => 19, "twenty" => 20
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

    numbers = range_str.scan(%r{[\d,]+(?:\.\d{2})?(?:k|K)?}).map do |num_str|
      num_str = num_str.gsub(",", "")
      multiplier = (num_str =~ /k$/i) ? 1000 : 1
      value = num_str.gsub(/k$/i, "").to_f
      (value * multiplier).to_i
    end
    numbers.size >= 2 ? [ numbers.min, numbers.max ] : nil
  end

  def extract_experience_requirement
    return nil if description.blank?

    text = description.is_a?(String) ? description : description.to_s

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
      [ match[1].to_i, match[2].to_i ]
    elsif (match = requirement.match(/(\d{1,2})\+/))
      [ match[1].to_i, match[1].to_i ]
    else
      nil
    end
  end

  def contract?
    return false if title.blank? && description.blank?

    text = [ title, description ].compact.join(" ")
    %w[contract contractor contract position].any? { |term| text.downcase.include?(term) }
  end

  def extracted_skills
    text = [ title, description ].compact.join(" ")
    return [] if text.blank?

    SKILL_PATTERNS.each_with_object([]) do |(skill, pattern), found|
      found << skill if text.match?(pattern)
    end
  end

  private

  def extract_word_based_experience(text)
    return nil if text.blank?

    words_pattern = NUMBER_WORDS.keys.join("|")

    range_regex = %r{(#{words_pattern})\s*(?:-|to)\s*(#{words_pattern})\s*(?:years?|yrs?)(?:\s+of\s+experience|\s+experience)?}i
    if (range_match = text.match(range_regex))
      min = number_word_to_i(range_match[1])
      max = number_word_to_i(range_match[2])
      return "#{min}-#{max} years" if min && max
    end

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
end
