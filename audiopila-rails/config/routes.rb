Rails.application.routes.draw do
  
  root 'audios#index'
  resources :audios
  # get 'settings/index'

  # get 'settings/create'

  # get 'settings/destroy'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :settings, except: [:show, :new, :edit]

  get '/sync_repo/:id', to: 'audios#sync_repo', as: :sync_repo
  
  get '/stream/:id', to: 'audios#stream', as: :stream
  
end
