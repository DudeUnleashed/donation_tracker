module Admin
  class AuthController < ApplicationController
    skip_before_action :authenticate_request, only: [:login, :register]

    def login
      admin = AdminUser.find_by(email: params[:email])
      if admin&.authenticate(params[:password])
        token = generate_token(admin)
        admin.update(last_login_at: Time.current)
        render json: { token: token, admin: admin.as_json(except: :password_digest) }
      else
        render json: { error: 'Invalid credentials' }, status: :unauthorized
      end
    end

    private

    def admin_params
      params.require(:admin).permit(:username, :email, :password, :password_confirmation)
    end

    def generate_token(admin)
      JWT.encode(
        { 
          admin_id: admin.id,
          exp: 24.hours.from_now.to_i
        },
        Rails.application.secrets.secret_key_base
      )
    end
  end
end
