class WebsiteUser < ApplicationRecord
  has_secure_password
  
  has_many :audit_logs
  
  validates :username, presence: true, uniqueness: true
  validates :password, presence: true, on: create
  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[admin viewer] }
  
  def admin?
    role == 'admin'
  end

  def viewer?
    role == 'viewer'
  end
end
