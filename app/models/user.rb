class User < ApplicationRecord
  has_secure_password
  has_many :job_applications, dependent: :destroy
  has_many :job_searches, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :password_confirmation, presence: true, if: -> { new_record? || !password.nil? }
  validates :api_token, uniqueness: true, allow_nil: true

  def regenerate_api_token!
    update!(api_token: SecureRandom.urlsafe_base64(32))
  end
end
