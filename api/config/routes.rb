# frozen_string_literal: true

Rails.application.routes.draw do
  mount ApiRoot => '/'

  namespace :admin do
    post '/auth/login', to: 'auth#login'
    post '/auth/register', to: 'auth#register'
    resources :csv_uploads, only: [:create, :index, :show]
  end
end
