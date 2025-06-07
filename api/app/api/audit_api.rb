
class AuditApi < Grape::API
  format :json
  prefix :api

  desc 'Get all audit logs'
  get '/audit_logs' do
    audit_logs = AuditLog.all
    present audit_logs, with: Entities::AuditLogEntity
  end

  helpers do
    def authenticated?
      current_user.present?
    end

  def current_user
    @current_user ||= begin
      token = headers['Authorization']&.split(' ')&.last
      User.find(JWT.decode(token, Rails.application.secrets.secret_key_base)[0]['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      nil
    end
  end
end
end
