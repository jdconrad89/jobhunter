module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_api_token!

    private

    def authenticate_api_token!
      token = request.authorization&.remove(/\ABearer /i)
      @current_user = User.authenticate_api_token(token)

      return if @current_user

      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    def current_user
      @current_user
    end
  end
end
