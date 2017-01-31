Rails.application.routes.draw do
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  
  ActiveAdmin.routes(self)
  
  # root to: 'home#index'

  scope '/1.0', defaults: {format: :json} do
  	post 'jel-api1', to: 'myapis#jel_api1' 
  end

  scope '/2.0', defaults: {format: :json} do
  	post 'jel-api1', to: 'catalog/catalog#jel_api1' 
  end

  resources :chat_rooms, only: [:new, :create, :show, :index]
  root 'chat_rooms#index'
  mount ActionCable.server => '/cable'
  
end
