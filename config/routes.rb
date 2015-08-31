Imageaudit::Application.routes.draw do
  root :to => 'home#index'
  resources :pages, :only => [:index, :show] do
    member do
      post :change_keeppublished
      post :set_notes
      put :set_notes
    end
  end

  resources :communities, :only => [:index, :show]

  resources :images, :only => [:index, :show] do
    member do
      post :change_stock
      post :change_communityreview
      post :change_staffreview
      post :set_notes
      put :set_notes
    end
  end

  # authentication
  match '/logout', to:'auth#end', :as => 'logout'
  match '/auth/:provider/callback', to: 'auth#success'

end
