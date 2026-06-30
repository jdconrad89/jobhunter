class AnalyticsController < ApplicationController
  before_action :require_login

  def index
    @analytics = JobPosts::Analytics.call(user: current_user)
    @synopsis = JobPosts::AnalyticsSynopsis.call(@analytics)
  end
end
