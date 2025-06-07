class ApplicationController < ActionController::Base
  before_action :authenticate_request
  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    begin
      decoded = JWT.decode(header, Rails.application.secrets.secret_key_base).first
      @current_user = User.find(decoded['user_id'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def require_admin
    unless current_user&.admin?
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end

  def log_deletion(record)
    AuditLog.log(
      action: 'deletion',
      record_type: record.class.name,
      record_id: record.id,
      user_id: current_user&.id,
      changes: record.attributes
    )
  end
end
