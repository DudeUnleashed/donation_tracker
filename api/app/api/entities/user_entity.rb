# frozen_string_literal: true

module Entities
  class UserEntity < Grape::Entity
    expose :id
    expose :username
    expose :email
    expose :donations, using: DonationEntity
  end
end
