Rails.application.routes.draw do

  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    unlocks: 'users/unlocks'
  }

  devise_scope :user do
    get '/volunteer/:id', :as => 'volunteer_to_drive_for_zone', to: redirect("/")
    get '/volunteer_to_drive/:id', to: redirect("/")
    get '/volunteer_to_drive', :as => 'volunteer_to_drive', to: redirect("/")
    # get '/volunteer/:id', :to => 'users/registrations#new', :as => 'volunteer_to_drive_for_zone'
    # get '/volunteer_to_drive/:id', to: redirect("/volunteer/%{id}")
    # get '/volunteer_to_drive', :to => 'users/registrations#new', :as => 'volunteer_to_drive'
    get "/users/sign_out" => "devise/sessions#destroy", :as => :get_destroy_user_session
  end

  # https://blog.heroku.com/real_time_rails_implementing_websockets_in_rails_5_with_action_cable
  # NOTE: to re-enable you also need to uncomment ./channels in application.js,
  # and the code in /channels/messages.js
  # and the meta tag in application.html.haml
  # and lined in development.rb and production.rb
  # Serve websocket cable requests in-process
  mount ActionCable.server => '/cable'

  require 'sidekiq/web'
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  root 'home#index'

  match '/confirm' => 'home#confirm', via: :get, as: :confirm
  match '/about' => 'home#about', via: :get, as: :about
  match '/code_of_conduct' => 'home#code_of_conduct', via: :get, as: :code_of_conduct
  match '/terms_of_service' => 'home#terms_of_service', via: :get, as: :terms_of_service
  match '/privacy' => 'home#privacy', via: :get, as: :privacy

  resources :dispatch, only: [:show] do
    member do
      get 'messages' => 'dispatch#messages'
      get 'ride_pane' => 'dispatch#ride_pane'
      get 'drivers' => 'dispatch#drivers'
      get 'flyer' => 'dispatch#flyer'
      get 'map' => 'dispatch#map'
    end
  end

  resources :driving do
    collection do
      get 'demo' => 'driving#demo'
      get 'status' => 'driving#status'
      post 'location' => 'driving#update_location'
      post 'available' => 'driving#available'
      post 'unavailable' => 'driving#unavailable'
      post 'accept_ride' => 'driving#accept_ride'
      post 'unaccept_ride' => 'driving#unaccept_ride'
      post 'pickup_ride' => 'driving#pickup_ride'
      post 'complete_ride' => 'driving#complete_ride'
      post 'cancel_ride' => 'driving#cancel_ride'
      get 'waiting_rides' => 'driving#waiting_rides'
      get 'ridezone_stats' => 'driving#ridezone_stats'
    end
  end

  get 'ride/:ride_zone_id' => 'rides#new', as: 'get_a_ride'
  get 'get_a_ride/:ride_zone_id', to: redirect("/ride/%{ride_zone_id}")
  get 'conseguir_un_paseo/:ride_zone_id' => 'rides#new'
  
  # get 'ride/:ride_zone_id', as: 'get_a_ride', to: redirect("/")
  # get 'get_a_ride/:ride_zone_id', to: redirect("/")
  # get 'conseguir_un_paseo/:ride_zone_id', to: redirect("/")

  resources :rides, only: [:create, :edit, :update]

  resources :users do
    get :confirm, on: :member
  end

  namespace :api do
    namespace :v1, path: '1' do
      post 'twilio/sms' => 'twilio#sms'
      post 'twilio/voice' => 'twilio#voice'
      get 'places/search' => 'places#search'

      resources :conversations, only: [:show, :update] do
        member do
          post 'messages' => 'conversations#create_message'
          post 'close' => 'conversations#close'
          post 'rides' => 'conversations#create_ride'
          post 'update_attribute' => 'conversations#update_attribute'
          post 'remove_help_needed' => 'conversations#remove_help_needed'
        end
      end

      resources :rides, only: [:update_attribute] do
        collection do
          if ENV['DTV_IS_WORKER'] == 'TRUE' || Rails.env.test?
            post 'confirm_scheduled' => 'rides#confirm_scheduled'
          end
        end
        member do
          post 'update_attribute' => 'rides#update_attribute'
        end
      end

      resources :ride_zones do
        member do
          post 'assign_ride' => 'ride_zones#assign_ride'
          get 'conversations' => 'ride_zones#conversations'
          post 'conversations' => 'ride_zones#create_conversation'
          get 'drivers' => 'ride_zones#drivers'
          get 'rides' => 'ride_zones#rides'
          post 'rides' => 'ride_zones#create_ride'
          post 'change_role'
        end
      end
    end
  end

  get '/admin', to: redirect('/admin/ride_zones')
  match '/admin/voters' => 'admin/users#voters', via: :get
  namespace :admin do
    resources :conversations, only: [:index, :show] do
      member do
        # get 'messages' => 'conversations#messages'
        # get 'ride_pane' => 'conversations#ride_pane'
        post 'close' => 'conversations#close'
        post 'blacklist_voter_phone' => 'conversations#blacklist_voter_phone'
        post 'unblacklist_voter_phone' => 'conversations#unblacklist_voter_phone'
      end
    end
    resources :drivers, only: [:index]
    resources :metrics, only: [:index]
    resources :rides
    get   'rides/csv/new' => 'ride_uploaded_files#new'
    post  'rides/csv' => 'ride_uploaded_files#create'
    get   'rides/csv/:id' => 'ride_uploaded_files#show', as: 'rides_csv_show'
    resources :ride_zones, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      member do
        get 'drivers'
        post 'add_role'
        post 'change_role'
        delete 'remove_role'
      end
    end
    resources :simulations, only: [:index] do
      collection do
        post 'start_new' => 'simulations#start_new'
        post 'clear_all_data' => 'simulations#clear_all_data'
      end
      member do
        post 'stop' => 'simulations#stop'
        delete 'delete' => 'simulations#delete'
      end
    end
    resource :site, only: [:show, :edit, :update]
    resources :users, only: [:show, :edit, :update, :index, :destroy] do
      member do
        post 'qa_clear' => 'users#qa_clear'
      end
    end
  end

end
