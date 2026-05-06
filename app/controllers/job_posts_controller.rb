class JobPostsController < ApplicationController
  before_action :require_login
  before_action :set_job_post, only: [ :show ]

  def index
    @job_posts = JobPost.filtered(params)
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
    permitted_params = job_post_params
    company_name = permitted_params.delete(:company_name)
    if company_name.to_s.strip.blank?
      @job_post = JobPost.new(permitted_params)
      @job_post.errors.add(:company, "name can't be blank")
      return render :new, status: :unprocessable_entity
    end


    company = Company.find_or_create_by(name: company_name.to_s.strip)
    job_post_info = permitted_params
    job_post_info[:company_id] = company.id

    unless company.persisted?
      @job_post = JobPost.new(job_post_info)
      @job_post.errors.add(:company, company.errors.full_messages.to_sentence.presence || "is invalid")
      return render :new, status: :unprocessable_entity
    end

    @job_post = JobPost.new(job_post_info)
    @job_post.company = company
    @job_post.job_search = manual_job_search_for_current_user

    if @job_post.save
      redirect_to job_post_path(@job_post), notice: "Job post created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_job_post
    @job_post = JobPost.find(params[:id])
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

  def manual_job_search_for_current_user
    current_user.job_searches.find_or_create_by!(job_title: "Manual Job Entries") do |job_search|
      job_search.language_code = "en"
      job_search.timezone = Time.zone.name
      job_search.location = "Anywhere"
      job_search.remote = true
      job_search.number_of_jobs = 0 if job_search.respond_to?(:number_of_jobs=)
    end
  end

  def job_posts_per_page
    per_page = params[:per_page].to_i
    return 10 if per_page <= 0

    allowed = [ 10, 20, 50 ]
    allowed.include?(per_page) ? per_page : 10
  end
end
