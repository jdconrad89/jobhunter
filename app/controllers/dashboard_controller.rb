class DashboardController < ApplicationController
  before_action :require_login

  APPLICATION_LIMIT_OPTIONS = [ 5, 10, 20, 50 ].freeze
  DEFAULT_APPLICATION_LIMIT = 10

  def index
    @job_searches = current_user.job_searches.order(created_at: :desc)

    @applications_limit = applications_limit_param
    applications_scope = current_user.job_applications
      .includes(job_post: :company)
      .order(applied_at: :desc)
    @applications_total_count = applications_scope.count
    @job_applications = applications_scope.limit(@applications_limit)
  end

  private

  def applications_limit_param
    limit = params[:applications_limit].to_i
    APPLICATION_LIMIT_OPTIONS.include?(limit) ? limit : DEFAULT_APPLICATION_LIMIT
  end
end
