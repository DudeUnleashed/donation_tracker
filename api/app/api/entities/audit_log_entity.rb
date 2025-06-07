module Entities
  class AuditLogEntity < Grape::Entity
    expose :action
    expose :changes
  end
end
