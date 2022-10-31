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

  resources :projects do
    resources :project_costs
    resources :project_users
    resources :draws do
      post 'approve_internal', to: 'draws#approve_internal'
      post 'reject_internal', to: 'draws#reject_internal'
      post 'submit', to: 'draws#submit'
    end
  end

  resources :draws do
    resources :draw_costs do
      post 'submit', to: 'draw_costs#submit'
    end
    resources :draw_documents do
      post 'approve', to: 'draw_documents#approve'
      post 'reject', to: 'draw_documents#reject'
    end
  end

  resources :draw_costs do
    resources :invoices do
      post 'submit', to: 'invoices#submit'
      post 'approve', to: 'invoices#approve'
      post 'reject', to: 'invoices#reject'
    end
  end

end
