# frozen_string_literal: true

module Resumes
  class Create
    Result = Data.define(:success?, :resume, :errors)

    def self.call(user:, attributes:)
      new(user: user, attributes: attributes).call
    end

    def initialize(user:, attributes:)
      @user = user
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      resume = @user.resumes.build(name: @attributes[:name])
      resume.is_default = ActiveModel::Type::Boolean.new.cast(@attributes[:is_default])
      resume.extraction_status = :pending
      resume.file.attach(@attributes[:file])

      if resume.save
        clear_other_defaults!(resume) if resume.is_default?
        ResumeTextExtractionJob.perform_later(resume.id)
        Result.new(success?: true, resume: resume, errors: nil)
      else
        Result.new(success?: false, resume: resume, errors: resume.errors.full_messages)
      end
    end

    private

    def clear_other_defaults!(resume)
      @user.resumes.where.not(id: resume.id).update_all(is_default: false)
    end
  end
end
