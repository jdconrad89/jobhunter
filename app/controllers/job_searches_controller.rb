class JobSearchesController < ApplicationController
  before_action :require_login
  before_action :set_job_search, only: [:show, :edit, :update, :destroy, :trigger]

  def index
    @job_searches = current_user.job_searches
  end

  def show
  end

  def new
    @job_search = current_user.job_searches.build
  end

  def create
    @job_search = current_user.job_searches.build(job_search_params)

    if @job_search.save
      redirect_to dashboard_path, notice: 'Job search was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @job_search.update(job_search_params)
      redirect_to dashboard_path, notice: 'Job search was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @job_search.destroy
    redirect_to dashboard_path, notice: 'Job search was successfully deleted.'
  end

  def trigger
    JobScraperJob.perform_later(@job_search)
    redirect_to dashboard_path, notice: 'Job search has been triggered and will run shortly.'
  end

  private

  def set_job_search
    @job_search = current_user.job_searches.find(params[:id])
  end

  def job_search_params
    permitted_params = params.require(:job_search).permit(:job_title, :location, :remote, :language_code, :runtime, :timezone, board_relevance: [])
    permitted_params[:board_relevance] = permitted_params[:board_relevance].reject(&:blank?) if permitted_params[:board_relevance].present?
    permitted_params
  end
end
