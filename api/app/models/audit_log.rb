class AuditLog < ApplicationRecord
  validates :action, presence: true
  validates :record_type, presence: true
end
