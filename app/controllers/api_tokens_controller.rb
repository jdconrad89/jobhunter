class ApiTokensController < ApplicationController
  before_action :require_login

  def show
    @api_token_plaintext = session.delete(:api_token_plaintext)
  end

  def create
    raw_token = current_user.regenerate_api_token!
    session[:api_token_plaintext] = raw_token
    redirect_to api_token_path, notice: "API token generated. Copy it now — it won't be shown again after you leave this page."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to api_token_path, alert: e.record.errors.full_messages.to_sentence
  end
end
