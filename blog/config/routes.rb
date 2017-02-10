Rails.application.routes.draw do
  resources :videos, only: [:new, :index, :destroy]

  devise_for :users
  root to: 'home#index' 
  
  resources :posts
  resources :authors
  resources :articles
  get 'search', to: 'search#search'
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
