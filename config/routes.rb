Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  authenticated :user, -> user { user.admin? }  do
    #mount Flipflop::Engine => "/flipflop"
    mount DelayedJobWeb, at: "/delayed_job"
  end

  devise_for :users, controllers: { sessions: 'users/sessions',
                                    confirmations: 'users/confirmations',
                                    unlocks: 'users/unlocks',
                                    passwords: 'users/passwords' }
  authenticated do
    root to: "home#index", as: :authenticated_root
  end
  root to: redirect('/users/sign_in')

  get '/about', to: 'home#about', as: :about

  resources :draws do
    resources :invoices
    resources :draw_costs
  end

  resources :organizations

  resources :projects do
    resources :project_costs
    resources :project_users
    resources :draws do
      post 'approve_internal', to: 'draws#approve_internal'
      post 'reject_internal', to: 'draws#reject_internal'
    end
  end

  resources :users

  resources :draw_costs do
    resources :invoices
  end

  #resources :draw_cost_requests do
    #post :add_document, to: 'draw_cost_requests#add_document'
    #post :remove_document, to: 'draw_cost_requests#remove_document'
    #resources :draw_cost_submissions
  #end
end
