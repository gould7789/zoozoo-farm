Rails.application.routes.draw do
  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # 認証（会員登録なし — Adminがアカウント発行）
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # 館（読み取り専用）→ 動物 → 記録（ネストルーティング）
  # health_records → health_logs に変更（内部テーブル名の隠蔽）
  resources :zones, only: [ :index, :show ] do
    resources :animal_categories, only: [ :create, :destroy ]
    resources :animals do
      resources :health_logs,     except: [ :show ], controller: "health_records"
      resources :feeding_records, except: [ :show ]
    end
  end

  # お知らせ（全体・館別統合）
  resources :notices, except: [ :show ]

  # 売上・経費（Admin専用）— _records パターンを隠蔽
  resources :sales,    except: [ :show ], controller: "sales_records"
  resources :expenses, except: [ :show ], controller: "expense_records"

  # マイページ
  resource :account, only: [ :show ]

  # ユーザー管理（Admin専用ネームスペース）— users → members に変更
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :members, except: [ :show ], controller: "users"
  end

  # ログイン後のルート
  root "zones#index"
end
