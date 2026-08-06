# frozen_string_literal: true

class Resume < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  has_many :resume_suggestions, dependent: :destroy

  ACCEPTED_CONTENT_TYPES = [
    "application/pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "text/plain"
  ].freeze

  MAX_FILE_SIZE = 5.megabytes

  enum :extraction_status, { pending: 0, completed: 1, failed: 2 }, prefix: true

  validates :name, presence: true
  validate :acceptable_file, if: -> { file.attached? }

  scope :default_first, -> { order(is_default: :desc, created_at: :desc) }

  def text_ready?
    extraction_status_completed? && extracted_text.present?
  end

  def pdf?
    file.attached? && file.blob.content_type == "application/pdf"
  end

  def docx?
    file.attached? && file.blob.content_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end

  def plain_text_file?
    file.attached? && file.blob.content_type == "text/plain"
  end

  private

  def acceptable_file
    unless ACCEPTED_CONTENT_TYPES.include?(file.blob.content_type)
      errors.add(:file, "must be a PDF, DOCX, or plain text file")
    end

    if file.blob.byte_size > MAX_FILE_SIZE
      errors.add(:file, "must be smaller than 5 MB")
    end
  end
end
