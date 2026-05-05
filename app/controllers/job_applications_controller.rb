class JobApplicationsController < ApplicationController
  before_action :require_login
  before_action :set_job_application, only: [:show, :edit, :update]

  STATUSES = %w[applied interviewing rejected ghosted].freeze

  def index
    @job_applications = current_user.job_applications.includes(job_post: :company).order(updated_at: :desc)
    @job_applications_by_status = @job_applications.group_by(&:status)
  end

  def create
    job_post = JobPost.find(params[:job_post_id])
    @job_application = current_user.job_applications.find_or_initialize_by(job_post: job_post)
    @job_application.status ||= "applied"
    @job_application.applied_at ||= Time.current

    if @job_application.save
      redirect_to job_post_path(job_post), notice: "Marked as applied."
    else
      redirect_to job_post_path(job_post), alert: @job_application.errors.full_messages.to_sentence
    end
  end

  def update
    if params[:status].present? && !STATUSES.include?(params[:status])
      return render json: { error: "Invalid status" }, status: :unprocessable_entity
    end

    if @job_application.update(job_application_params)
      respond_to do |format|
        format.html { redirect_to job_applications_path, notice: "Application updated." }
        format.json { render json: { ok: true, status: @job_application.status } }
      end
    else
      respond_to do |format|
        format.html { redirect_to job_applications_path, alert: @job_application.errors.full_messages.to_sentence }
        format.json { render json: { error: @job_application.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
  end

  def show
    # renders show template
  end

  def edit
    # renders edit template
  end

  private

  def set_job_application
    @job_application = current_user.job_applications.find(params[:id])
  end

  def job_application_params
    params.permit(:status, :contact_info, :followed_up, job_application: [:status, :contact_info, :followed_up]).yield_self do |p|
      if p[:job_application].present?
        p.require(:job_application).permit(:status, :contact_info, :followed_up)
      else
        p.slice(:status, :contact_info, :followed_up)
      end
    end
  end
end
