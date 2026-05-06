# frozen_string_literal: true

module JobPost::SimilarListings
  extend ActiveSupport::Concern

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
end
