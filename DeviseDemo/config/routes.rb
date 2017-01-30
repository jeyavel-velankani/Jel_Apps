Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#index'

  get '/secret', to: 'pages#secret', as: :secret

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
