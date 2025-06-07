class AdminUser < ApplicationRecord
  has_secure_password

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[super_admin admin] }

  def super_admin?
    role == 'super_admin'
  end
end
