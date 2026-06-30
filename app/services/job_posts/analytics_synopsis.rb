# frozen_string_literal: true

module JobPosts
  class AnalyticsSynopsis
    Result = Data.define(:paragraphs)

    def self.call(analytics)
      new(analytics).call
    end

    def initialize(analytics)
      @analytics = analytics
    end

    def call
      return Result.new(paragraphs: [ no_data_message ]) if @analytics.total_posts.zero?

      Result.new(paragraphs: [
        coverage_paragraph,
        experience_paragraph,
        skills_paragraph,
        market_paragraph
      ].compact)
    end

    private

    def no_data_message
      "Add job postings with descriptions to build an analysis synopsis. " \
        "Experience, salary, and skills are extracted automatically from listing text."
    end

    def coverage_paragraph
      total = @analytics.total_posts
      with_exp = @analytics.posts_with_experience
      with_pay = @analytics.posts_with_salary
      with_both = @analytics.salary_points.size

      parts = [ "You are tracking #{total} job #{'posting'.pluralize(total)}." ]
      parts << "#{with_exp} (#{percentage(with_exp, total)}%) mention years of experience"
      parts << "#{with_pay} (#{percentage(with_pay, total)}%) include salary information"
      parts << "#{with_both} (#{percentage(with_both, total)}%) include both, which powers the salary–experience charts."

      parts.join(", ") + "."
    end

    def experience_paragraph
      breakdown = @analytics.experience_breakdown.select { |row| row[:count].positive? }
      return nil if breakdown.empty?

      total_mentions = breakdown.sum { |row| row[:count] }
      top = breakdown.max_by { |row| row[:count] }
      top_share = percentage(top[:count], total_mentions)

      secondary = breakdown
        .reject { |row| row[:label] == top[:label] }
        .sort_by { |row| -row[:count] }
        .first(2)
        .select { |row| row[:count].positive? }

      text = "Experience demand is strongest in the #{top[:label]} band (#{top[:count]} postings, #{top_share}% of tagged listings)."
      if secondary.any?
        also = secondary.map { |row| "#{row[:label]} (#{row[:count]})" }.join(" and ")
        text += " Notable secondary clusters appear at #{also}."
      end

      text
    end

    def skills_paragraph
      skills = @analytics.top_skills
      return nil if skills.empty?

      total = @analytics.total_posts
      leader = skills.first
      text = "#{leader[:skill]} is the most requested skill, appearing in #{leader[:count]} of #{total} postings " \
             "(#{percentage(leader[:count], total)}%)."

      runners_up = skills.drop(1).first(4)
      if runners_up.any?
        list = runners_up.map { |row| "#{row[:skill]} (#{row[:count]})" }.to_sentence
        text += " Other frequently mentioned skills include #{list}."
      end

      text
    end

    def market_paragraph
      points = @analytics.salary_points
      return nil if points.empty?

      avg_pay = points.sum { |point| midpoint(point[:pay_min], point[:pay_max]) } / points.size.to_f
      avg_exp = points.sum { |point| midpoint(point[:exp_min], point[:exp_max]) } / points.size.to_f

      mid_career = Analytics.salary_distribution_for(
        points: points,
        experience_min: 2,
        experience_max: 8
      )
      mid_top = peak_bucket(mid_career)

      mid_salary = Analytics.experience_distribution_for(
        points: points,
        salary_min: 100_000,
        salary_max: 175_000
      )
      salary_top = peak_bucket(mid_salary)

      text = "Across postings with both salary and experience data, the typical midpoint is about " \
             "#{format_years(avg_exp)} of experience and #{format_dollars(avg_pay)} in compensation."

      if mid_top
        text += " For roughly 2–8 years of experience, the most common salary band is #{mid_top[:label]} " \
                "(#{mid_top[:count]} postings, #{mid_top[:percentage]}% of that cohort)."
      end

      if salary_top
        text += " Roles advertising #{format_dollars(100_000)}–#{format_dollars(175_000)} most often ask for " \
                "#{salary_top[:label]} of experience (#{salary_top[:percentage]}% of that salary range)."
      end

      text
    end

    def peak_bucket(distribution)
      return nil if distribution[:matching_posts].zero?

      index = distribution[:counts].each_with_index.max_by { |count, _| count }&.last
      return nil if index.nil? || distribution[:counts][index].zero?

      {
        label: distribution[:labels][index],
        count: distribution[:counts][index],
        percentage: distribution[:percentages][index]
      }
    end

    def midpoint(min, max)
      (min + max) / 2.0
    end

    def percentage(part, whole)
      return 0 if whole.zero?

      (part.to_f / whole * 100).round
    end

    def format_years(value)
      rounded = value.round(1)
      rounded == rounded.to_i ? "#{rounded.to_i} years" : "#{rounded} years"
    end

    def format_dollars(value)
      amount = value.round(-3)
      "$#{Analytics.format_k(amount)}"
    end
  end
end
