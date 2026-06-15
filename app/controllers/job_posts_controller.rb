class JobPostsController < ApplicationController
  before_action :require_login
  before_action :set_job_post, only: [ :show ]

  def index
    @job_posts = JobPost.filtered(job_post_filter_params)
      .page(params[:page])
      .per(job_posts_per_page)
    @applied_job_post_ids = current_user.job_applications.where(job_post_id: @job_posts.map(&:id)).pluck(:job_post_id)
  end

  def show
    @suggested_job_posts = @job_post.suggested_jobs(limit: 4)
    @job_application = current_user.job_applications.find_by(job_post: @job_post)
  end

  def new
    @job_post = JobPost.new
  end

  def create
    result = JobPosts::CreateManual.call(user: current_user, attributes: job_post_params)

    if result.success?
      redirect_to job_post_path(result.job_post), notice: "Job post created."
    else
      @job_post = result.job_post
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_job_post
    @job_post = JobPost.find(params[:id])
  end

  def job_post_filter_params
    params.permit(:company, :remote, :position_type, :pay_range, :experience_range)
  end

  def job_post_params
    params.require(:job_post).permit(
      :title,
      :website,
      :description,
      :location,
      :remote,
      :company_name
    )
  end

  def job_posts_per_page
    per_page = params[:per_page].to_i
    return 10 if per_page <= 0

    allowed = [ 10, 20, 50 ]
    allowed.include?(per_page) ? per_page : 10
  end
end
