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

  resources :organizations
  resources :users
  resources :draws do
    resources :draw_costs
    resources :draw_cost_requests
    resources :draw_cost_submissions
  end
  resources :projects do
    resources :draws
    resources :project_users
  end
  resources :draw_costs do
    resources :draw_cost_requests do
      post :add_document, to: 'draw_cost_requests#add_document'
      post :remove_document, to: 'draw_cost_requests#remove_document'
    end
  end
end
