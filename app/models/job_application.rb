class JobApplication < ApplicationRecord
  belongs_to :user
  belongs_to :job_post

  validates :applied_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[applied interviewing rejected ghosted] }
  validates :job_post_id, uniqueness: { scope: :user_id }
  validate :status_not_ghosted_if_recent_update

  before_validation :set_initial_status, on: :create
  before_save :update_ghosted_status

  private

  def set_initial_status
    self.status ||= 'applied'
    self.applied_at ||= Time.current
  end

  def update_ghosted_status
    if status != 'ghosted' && updated_at && updated_at < 2.weeks.ago
      self.status = 'ghosted'
    end
  end

  def status_not_ghosted_if_recent_update
    if status == 'ghosted' && updated_at && updated_at > 2.weeks.ago
      errors.add(:status, "cannot be ghosted if there was a recent update")
    end
  end
end 