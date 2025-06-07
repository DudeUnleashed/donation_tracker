# frozen_string_literal: true
require 'grape'
require_relative '../helpers/api_helpers.rb'

class UserApi < Grape::API
  helpers APIHelpers
  format :json
  prefix :api

    desc 'Get all users'
    get '/users' do
      users = User.all
      present users, with: Entities::UserEntity
    end

    desc 'Search users by username or email'
    params do
      requires :query, type: String, desc: 'Search query'
    end
    get '/users/search' do
      users = User.where('username LIKE ? OR email LIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
      present users, with: Entities::UserEntity
    end    

    desc 'Create a user'
    params do
      requires :username, type: String, desc: 'Username'
      requires :email, type: String, desc: 'Email'
      optional :donations, type: Array[Hash], desc: 'Donations'
    end
    post '/users' do
      user = User.create!(username: params[:username], email: params[:email])
      #log_audit(action: 'user_added', changes: user.to_json)

      if params[:donations].present?
        params[:donations].each do |donation|
          user.donations.create!(amount: donation[:amount])
          #log_audit(action: 'donation_added', changes: donation.to_json)
        end
      end

      present user, with: Entities::UserEntity
    end

    desc 'Add a donation to a user'
    params do
      requires :user_id, type: Integer, desc: 'User ID'
      requires :amount, type: Float, desc: 'Donation amount'
      requires :donation_date, type: String, desc: 'Donation date'
    end
    post '/donations' do
      user = User.find(params[:user_id])

      donation = user.donations.create!(
        amount: params[:amount],
        platform: 'Manual', 
        donation_date: params[:donation_date])

      #log_audit(action: 'donation_added', changes: donation.to_json)
      present donation, with: Entities::DonationEntity
    end

    desc 'Delete a user'
    params do
      requires :id, type: Integer, desc: 'User ID'
    end
    delete '/users/:id' do
      user = User.find(params[:id])
      #deleted_user = user.to_json
      if user.destroy
        #log_audit(action: 'user_deleted', changes: deleted_user)
        status 200
      else
        status 422
      end
    end

    desc 'Delete a donation'
    params do
      requires :id, type: Integer, desc: 'Donation ID'
    end
    delete '/donations/:id' do
      donation = Donation.find(params[:id])
      #deleted_donation = donation.as_json
      if donation.destroy
        #log_audit(action: 'donation_deleted', changes: deleted_donation)
        status 200
      else
        status 422
      end
    end

end
