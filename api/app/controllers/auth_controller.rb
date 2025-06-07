class AuthController < ApplicationController
  def login
    user = WebsiteUser.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      token = JWT.encode({ user_id: user.id }, Rails.application.secrets.secret_key_base)
      render json: { 
        user: user.as_json(except: :password_digest),
        token: token 
      }
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end
end
