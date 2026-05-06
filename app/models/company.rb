class Company < ApplicationRecord
  has_many :job_posts, dependent: :destroy

  validates :name, presence: true


  # TODO: Add logic to manually add information about a company and also view all JobPosts/JobApplications for a company
end
