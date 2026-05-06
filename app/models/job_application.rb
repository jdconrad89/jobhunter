class JobApplication < ApplicationRecord
  belongs_to :user
  belongs_to :job_post

  validates :applied_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[applied interviewing rejected ghosted] }
  validates :job_post_id, uniqueness: { scope: :user_id }

  before_validation :set_initial_status, on: :create

  private

  def set_initial_status
    self.status ||= 'applied'
    self.applied_at ||= Time.current
  end
end 