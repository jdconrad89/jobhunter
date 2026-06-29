# frozen_string_literal: true

module JobPosts
  class Analytics
    EXPERIENCE_BUCKETS = [
      { label: "0-2 yrs", min: 0, max: 2 },
      { label: "2-4 yrs", min: 2, max: 4 },
      { label: "4-6 yrs", min: 4, max: 6 },
      { label: "6-8 yrs", min: 6, max: 8 },
      { label: "8-10 yrs", min: 8, max: 10 },
      { label: "10-12 yrs", min: 10, max: 12 },
      { label: "12+ yrs", min: 12, max: 99 }
    ].freeze

    SALARY_BUCKET_SIZE = 25_000
    SALARY_RANGE_MIN = 50_000
    SALARY_RANGE_MAX = 300_000
    TOP_SKILLS_LIMIT = 15

    Result = Data.define(
      :total_posts,
      :posts_with_experience,
      :posts_with_salary,
      :experience_breakdown,
      :top_skills,
      :salary_points
    )

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      posts = scoped_posts.to_a

      Result.new(
        total_posts: posts.size,
        posts_with_experience: posts.count { |post| experience_bounds(post) },
        posts_with_salary: posts.count { |post| pay_bounds(post) },
        experience_breakdown: experience_breakdown(posts),
        top_skills: top_skills(posts),
        salary_points: salary_points(posts)
      )
    end

    def self.salary_distribution_for(points:, experience_min:, experience_max:)
      exp_min = experience_min.to_i
      exp_max = experience_max.to_i
      exp_max = exp_min if exp_max < exp_min

      buckets = salary_buckets
      counts = buckets.to_h { |bucket| [ bucket[:label], 0 ] }
      matching_posts = 0

      points.each do |point|
        next unless ranges_overlap?(point[:exp_min], point[:exp_max], exp_min, exp_max)

        matching_posts += 1

        distribute_range_across_buckets(
          range_min: point[:pay_min],
          range_max: point[:pay_max],
          bucket_size: SALARY_BUCKET_SIZE,
          range_floor: SALARY_RANGE_MIN,
          range_ceiling: SALARY_RANGE_MAX
        ) do |bucket_label|
          counts[bucket_label] += 1 if counts.key?(bucket_label)
        end
      end

      {
        labels: buckets.map { |bucket| bucket[:label] },
        counts: buckets.map { |bucket| counts[bucket[:label]] },
        matching_posts: matching_posts
      }
    end

    def self.ranges_overlap?(left_min, left_max, right_min, right_max)
      left_min <= right_max && left_max >= right_min
    end

    def self.distribute_range_across_buckets(range_min:, range_max:, bucket_size:, range_floor:, range_ceiling:)
      clipped_min = [ range_min, range_floor ].max
      clipped_max = [ range_max, range_ceiling ].min
      return if clipped_min > clipped_max

      bucket_start = ((clipped_min - range_floor) / bucket_size.to_f).floor * bucket_size + range_floor
      while bucket_start <= clipped_max
        bucket_end = bucket_start + bucket_size - 1
        if ranges_overlap?(range_min, range_max, bucket_start, bucket_end)
          label = salary_label_for(bucket_start, bucket_end)
          yield label
        end
        bucket_start += bucket_size
      end
    end

    def self.salary_label_for(bucket_min, bucket_max)
      if bucket_max >= SALARY_RANGE_MAX
        "$#{format_k(bucket_min)}+"
      else
        "$#{format_k(bucket_min)}-#{format_k(bucket_max)}"
      end
    end

    def self.format_k(amount)
      amount >= 1000 ? "#{amount / 1000}k" : amount.to_s
    end

    def self.salary_buckets
      buckets = []
      start = SALARY_RANGE_MIN

      while start < SALARY_RANGE_MAX
        bucket_end = start + SALARY_BUCKET_SIZE - 1
        buckets << {
          min: start,
          max: bucket_end,
          label: salary_label_for(start, bucket_end)
        }
        start += SALARY_BUCKET_SIZE
      end

      buckets << {
        min: SALARY_RANGE_MAX,
        max: Float::INFINITY,
        label: salary_label_for(SALARY_RANGE_MAX, SALARY_RANGE_MAX + SALARY_BUCKET_SIZE - 1)
      }
      buckets
    end

    private

    def scoped_posts
      JobPost.joins(:job_search).where(job_searches: { user_id: @user.id })
    end

    def experience_breakdown(posts)
      EXPERIENCE_BUCKETS.map do |bucket|
        count = posts.count do |post|
          bounds = experience_bounds(post)
          next false unless bounds

          self.class.ranges_overlap?(bounds[0], bounds[1], bucket[:min], bucket[:max])
        end

        { label: bucket[:label], count: count }
      end
    end

    def top_skills(posts)
      counts = Hash.new(0)

      posts.each do |post|
        post.extracted_skills.each do |skill|
          counts[skill] += 1
        end
      end

      counts
        .sort_by { |_, count| -count }
        .first(TOP_SKILLS_LIMIT)
        .map { |skill, count| { skill: skill, count: count } }
    end

    def salary_points(posts)
      posts.filter_map do |post|
        experience = experience_bounds(post)
        pay = pay_bounds(post)
        next unless experience && pay

        {
          exp_min: experience[0],
          exp_max: experience[1],
          pay_min: pay[0],
          pay_max: pay[1]
        }
      end
    end

    def experience_bounds(post)
      min = post.experience_years_min
      max = post.experience_years_max

      if min.nil? && max.nil?
        parsed = post.parse_experience_years
        return parsed if parsed

        return nil
      end

      [ min || max, max || min ]
    end

    def pay_bounds(post)
      min = post.pay_range_min
      max = post.pay_range_max

      if min.nil? && max.nil?
        parsed = post.parse_pay_range_numbers
        return parsed if parsed

        return nil
      end

      [ min || max, max || min ]
    end
  end
end
