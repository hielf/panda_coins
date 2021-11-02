require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  root 'home#index'
  resources :trade_orders do
    collection do
      get :pre_orders
      get :event_logs
      get :histroy_matchresults
      get :trader_balances
      get :accounts_history
      get :production_log
    end
  end

  resources :trader_settings, only: [:edit, :update]# do
    # collection do
    #   get :account_settings
    # end
  # end

  namespace :api, defaults: {format: :json} do
    root 'root#home'
    resources :trade_orders do
      collection do
        get :pre_orders
        get :tickers
        get :event_logs
        get :positions
        get :account_values
        get :contract_data
        post :position_check
        get :trades_data
        get :test
        get :white_list
      end
    end
    match '*path', via: :all, to: 'root#route_not_found'
  end
  match '*path', via: :all, to: 'home#route_not_found'

end
