Rails.application.routes.draw do
  resources :widgets
  resources :jobs
  get 'messages/reply'

  resources :users
  get 'welcome/index'
  get 'welcome/give_time'
  get 'welcome/myhaml'
  post 'welcome/name_save'
  resources :articles
  
  resource :messages do
	  collection do
	    post 'reply'
	  end
  end

  root 'welcome#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
