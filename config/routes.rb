Rails.application.routes.draw do

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  authenticated :user, -> user { user.admin? }  do
    mount DelayedJobWeb, at: "/delayed_job"
  end

  namespace :api do
    namespace :v1 do
      get 'docs/swagger.:format', to: "swagger#index"
      get 'docs', to: "swagger#apidocs"
      resources :leads, only: [:index, :create ]
      get 'leads/prospect_stats', to: "leads#prospect_stats"
      resources :messages, only: [:create]
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

  #post '/scheduled_actions/conflict_check', to: 'scheduled_actions#conflict_check'

  resources :scheduled_actions do
    collection do
      get :conflict_check, to: 'scheduled_actions#conflict_check'
    end
    member do
      post 'complete', to: 'scheduled_actions#complete'
      get 'completion_form', to: 'scheduled_actions#completion_form'
    end
  end
  resources :notes
  resources :reasons
  resources :roles
  resources :unit_types
  resources :units
  resources :users do
  end
  #resources :residents
  resources :engagement_policies

  resources :properties do
    resources :units
    resources :unit_types
    resources :residents
    member do
      get 'duplicate_leads', to: 'properties#duplicate_leads'
    end
  end

  resources :leads do
    collection do
      get 'search', to: "leads#search"
    end
    member do
      post 'trigger_state_event', to: "leads#trigger_state_event"
      post 'mark_messages_read', to: "leads#mark_messages_read"
      get 'call_log_partial', to: "leads#call_log_partial"
      get 'progress_state', to: "leads#progress_state"
      post 'update_state', to: "leads#update_state"
    end
    resources :messages do
      post 'deliver', on: :member
      post 'mark_read', to: "messages#mark_read"
    end
  end

  resources :lead_sources do
    post 'reset_token', on: :member
  end

  resources :messages do
    post 'deliver', on: :member
    post 'mark_read', to: "messages#mark_read"
    get 'body_preview', to: "messages#body_preview"
  end

  resources :message_templates

  namespace :stats do
    get 'manager', to: "manager"
  end

  namespace :home do
    get 'manager_dashboard', to: 'manager_dashboard'
    get 'dashboard', to: 'dashboard'
  end

  resources :teams do
    member do
      post 'add_member', to: 'add_member'
    end
  end

  get '/messaging/preferences', to: 'home#messaging_preferences', as: 'messaging_preferences'
  post '/messaging/unsubscribe', to: 'home#unsubscribe', as: 'messaging_unsubscribe'

end
