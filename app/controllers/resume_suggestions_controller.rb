# frozen_string_literal: true

class ResumeSuggestionsController < ApplicationController
  before_action :require_login
  before_action :require_resume_recommendations!
  before_action :set_job_post

  def create
    resume = current_user.resumes.find(params[:resume_id])

    unless resume.text_ready?
      redirect_to job_post_path(@job_post), alert: "Resume text is not ready yet. Wait for extraction to complete."
      return
    end

    suggestion = ResumeSuggestion.find_or_initialize_by(resume: resume, job_post: @job_post)
    suggestion.update!(status: :pending, suggestions: {}, error_message: nil)
    ResumeSuggestionJob.perform_later(suggestion.id)

    redirect_to job_post_path(@job_post, resume_id: resume.id), notice: "Generating resume suggestions..."
  end

  def show
    resume = current_user.resumes.find(params[:resume_id])
    suggestion = resume.resume_suggestions.find_by!(job_post: @job_post)

    render json: {
      status: suggestion.status,
      suggestions: suggestion.suggestions,
      error_message: suggestion.error_message
    }
  end

  private

  def set_job_post
    @job_post = JobPost.find(params[:job_post_id])
  end
end
