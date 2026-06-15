Rails.application.routes.draw do
  root "dashboard#index"

  resources :job_searches do
    member do
      post :trigger
    end
  end

  resources :job_posts, only: [ :index, :show, :new, :create ] do
    resources :job_applications, only: [ :create ]
  end

  resources :job_applications, only: [ :index, :show, :edit, :update ]

  get "dashboard", to: "dashboard#index"

  get "signup", to: "users#new"
  post "signup", to: "users#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resource :api_token, only: [ :show, :create ]

  namespace :api do
    resources :job_posts, only: [ :index, :create ]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
