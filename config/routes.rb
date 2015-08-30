Imageaudit::Application.routes.draw do
  root :to => 'home#index'
  resources :pages, :only => [:index, :show]
  resources :communities, :only => [:index, :show]
  resources :images, :only => [:index, :show]

  # authentication
  match '/logout', to:'auth#end', :as => 'logout'
  match '/auth/:provider/callback', to: 'auth#success'

end
