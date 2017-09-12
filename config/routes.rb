Rails.application.routes.draw do

  root to: 'documents#index'

  resources :documents, only: :index

end
