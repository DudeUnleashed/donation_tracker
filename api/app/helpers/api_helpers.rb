module APIHelpers
  def log_audit(action:, changes: nil)
    AuditLog.create!(
      action: action,
      changes: changes || record.as_json
    )
  end
end