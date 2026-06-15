class ApiTokensController < ApplicationController
  before_action :require_login

  def show
    @api_token_supported = User.column_names.include?("api_token")
  end

  def create
    unless User.column_names.include?("api_token")
      redirect_to api_token_path, alert: "API tokens are not set up yet. Run bin/rails db:migrate and restart the server."
      return
    end

    current_user.regenerate_api_token!
    redirect_to api_token_path, notice: "API token generated. Copy it now — it won't be shown again after you leave this page."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to api_token_path, alert: e.record.errors.full_messages.to_sentence
  end
end
