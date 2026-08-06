# frozen_string_literal: true

class ResumeSuggestion < ApplicationRecord
  belongs_to :resume
  belongs_to :job_post

  enum :status, { pending: 0, completed: 1, failed: 2 }

  validates :resume_id, uniqueness: { scope: :job_post_id }
end
