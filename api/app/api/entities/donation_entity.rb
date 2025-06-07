
module Entities
  class DonationEntity < Grape::Entity
    expose :id
    expose :amount
    expose :platform
    expose :donation_date
  end
end
