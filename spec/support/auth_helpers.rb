module AuthHelpers
  def sign_in_as(user, password: "password")
    post login_path, params: { email: user.email, password: password }
  end

  def api_auth_headers(user)
    token = user.instance_variable_get(:@plain_api_token) || user.regenerate_api_token!
    { "Authorization" => "Bearer #{token}" }
  end
end
