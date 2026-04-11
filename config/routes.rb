Rails.application.routes.draw do
  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # 認証（会員登録なし — Adminがアカウント発行）
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # 館（読み取り専用）→ 動物 → 記録（ネストルーティング）
  resources :zones, only: [ :index, :show ] do
    resources :animals do
      resources :health_records,  except: [ :show ]
      resources :feeding_records, except: [ :show ]
    end
  end

  # お知らせ（全体・館別統合）
  resources :notices, except: [ :show ]

  # 売上・経費（Admin専用）
  resources :sales_records,   except: [ :show ]
  resources :expense_records, except: [ :show ]

  # マイページ
  resource :account, only: [ :show ]

  # ユーザー管理（Admin専用ネームスペース）
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :users, only: [ :index, :new, :create, :edit, :update ]
  end

  # ログイン後のルート
  root "zones#index"
end
