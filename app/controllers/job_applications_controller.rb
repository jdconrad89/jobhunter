class JobApplicationsController < ApplicationController
  before_action :require_login
  before_action :set_job_application, only: [ :show, :edit, :update ]

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
    if params[:status].present? && !JobApplication::STATUSES.include?(params[:status])
      return render json: { error: "Invalid status" }, status: :unprocessable_entity
    end

    attrs = ghosted_checkbox_merged_attributes(job_application_params)

    if @job_application.update(attrs)
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
    params.permit(:status, :contact_info, :followed_up, job_application: [ :status, :contact_info, :followed_up ]).yield_self do |p|
      if p[:job_application].present?
        p.require(:job_application).permit(:status, :contact_info, :followed_up)
      else
        p.slice(:status, :contact_info, :followed_up)
      end
    end
  end

  # HTML form sends top-level mark_as_ghosted ("0" / "1"). JSON/drag-drop omit it and use status only.
  def ghosted_checkbox_merged_attributes(permitted)
    return permitted unless params.key?(:mark_as_ghosted)

    h = permitted.to_h.symbolize_keys
    if params[:mark_as_ghosted] == "1"
      h[:status] = "ghosted"
    elsif h[:status] == "ghosted"
      h[:status] = "applied"
    end
    h
  end
end
