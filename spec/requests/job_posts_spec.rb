require "rails_helper"

RSpec.describe "JobPosts", type: :request do
  describe "GET /job_posts" do
    it "redirects to login when logged out" do
      get job_posts_path
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(login_path)
    end

    it "returns http success when logged in" do
      user = create_user!
      sign_in_as(user)

      get job_posts_path
      expect(response).to have_http_status(:success)
    end
  end
end
