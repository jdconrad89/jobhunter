class Company < ApplicationRecord
  has_many :job_posts, dependent: :destroy

  validates :name, presence: true
end
