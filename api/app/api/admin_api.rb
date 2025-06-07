# frozen_string_literal: true

require 'grape'
require 'jwt'

class AdminApi < Grape::API
  format :json
  prefix :api

  helpers do
    def generate_token(admin_id)
      payload = {
        admin_id: admin_id,
        exp: Time.now.to_i + (24 * 60 * 60) # Token expires in 24 hours
      }
      
      JWT.encode(payload, Rails.application.credentials.secret_key_base)
    end
  end

  desc 'Admin login'
  params do
    requires :email, type: String, desc: 'Admin email'
    requires :password, type: String, desc: 'Admin password'
  end
  post '/auth/login' do
    # Find the admin by email
    admin = WebsiteUser.find_by(email: params[:email])
    
    if admin && admin.authenticate(params[:password])
      # Authentication successful
      token = generate_token(admin.id)
      
      {
        success: true,
        token: token,
        admin: {
          id: admin.id,
          email: admin.email,
          role: admin.role || 'viewer'
        }
      }
    else
      # Authentication failed
      error!({
        success: false,
        message: 'Invalid email or password'
      }, 401)
    end
  end

  desc 'Verify token'
  params do
    requires :token, type: String, desc: 'JWT token'
  end
  post '/auth/verify_token' do
    begin
      decoded_token = JWT.decode(params[:token], Rails.application.credentials.secret_key_base)[0]
      admin_id = decoded_token['admin_id']
      
      admin = WebsiteUser.find_by(id: admin_id)
      
      if admin
        {
          success: true,
          admin: {
            id: admin.id,
            email: admin.email,
            role: admin.role || 'viewer'
          }
        }
      else
        error!({
          success: false,
          message: 'Admin not found'
        }, 404)
      end
    rescue JWT::ExpiredSignature
      error!({
        success: false,
        message: 'Token has expired'
      }, 401)
    rescue JWT::DecodeError
      error!({
        success: false,
        message: 'Invalid token'
      }, 401)
    end
  end
end