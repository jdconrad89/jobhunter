class DashboardController < ApplicationController
  before_action :require_login

  def index
    @job_searches = current_user.job_searches.order(created_at: :desc)
    @job_applications = current_user.job_applications.includes(:job_post).order(created_at: :desc)
  end
end
