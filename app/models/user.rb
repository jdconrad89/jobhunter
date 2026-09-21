class User < ApplicationRecord
  has_secure_password
  has_many :job_applications, dependent: :destroy
  has_many :job_searches, dependent: :destroy
  has_many :resumes, dependent: :destroy

  # Signed, expiring tokens — no DB columns required (avoids stale-schema
  # failures after migrate without a server restart).
  generates_token_for :password_reset, expires_in: 2.hours do
    password_digest
  end

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  validates :password_confirmation, presence: true, if: -> { new_record? || !password.nil? }
  validates :api_token_digest, uniqueness: true, allow_nil: true

  def api_token_configured?
    api_token_digest.present?
  end

  def regenerate_api_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update!(api_token_digest: self.class.digest_api_token(raw_token))
    @plain_api_token = raw_token
    raw_token
  end

  def self.authenticate_api_token(raw_token)
    return if raw_token.blank?

    find_by(api_token_digest: digest_api_token(raw_token))
  end

  def self.digest_api_token(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
