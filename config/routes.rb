Rails.application.routes.draw do

  resources :resident_details
  resources :residents
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  namespace :api do
    namespace :v1 do
      get 'docs/swagger.:format', to: "swagger#index"
      get 'docs', to: "swagger#apidocs"
      resources :leads
    end
  end

  devise_for :users, controllers: { sessions: 'users/sessions',
                                    confirmations: 'users/confirmations',
                                    unlocks: 'users/unlocks',
                                    passwords: 'users/passwords' }

  authenticated do
    root to: "home#dashboard", as: :authenticated_root
  end

  root to: redirect('/users/sign_in')

  resources :lead_actions
  resources :notes
  resources :reasons
  resources :roles
  resources :unit_types
  resources :units
  resources :users

  resources :properties do
    resources :units
    resources :unit_types
  end

  resources :leads do
    collection do
      get 'search', to: "leads#search"
    end
    member do
      post 'trigger_state_event', to: "leads#trigger_state_event"
    end
  end

  resources :lead_sources do
    post 'reset_token', on: :member
  end


end
