Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # 인증 (회원가입 없음 — Admin 이 계정을 발급한다)
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # 관(읽기 전용) → 동물 → 기록 (중첩 라우팅)
  # URL 세그먼트는 테이블명을 그대로 쓰지 않는다 — 도메인의 말로 읽히게 하고
  # controller: 로 잇는다. 컨트롤러·모델·뷰 폴더명은 테이블명을 따른다
  resources :zones, only: [ :index, :show ] do
    resources :animal_categories, only: [ :create, :update, :destroy ] do
      member do
        patch :toggle
      end
    end
    resources :animals do
      # 되돌릴 수 없는 조작은 라우트부터 나눈다 — destroy 에 플래그로 섞으면
      # 파라미터 하나 차이로 복구 불가능한 일이 일어난다
      member do
        post   :restore
        delete :purge
      end
      # 프로필 사진 삭제 — 한 동물에 한 장이므로 단수 리소스
      resource  :photo, only: [ :destroy ], controller: "animal_photos"
      resources :health_logs,  except: [ :show ], controller: "health_records"
      resources :feeding_logs, except: [ :show ], controller: "feeding_records"
    end
  end

  # 내보낸 개체 보관 — 관을 가로지르므로 zones 아래에 둘 수 없다
  get "/archive", to: "animal_archives#index", as: :archive

  resources :notices

  # 매출·지출 (Admin 전용)
  resources :sales,    except: [ :show ], controller: "sales_records"
  resources :expenses, except: [ :show ], controller: "expense_records"

  resource :account, only: [ :show ]

  # 사용자 관리 (Admin 전용 네임스페이스)
  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :members, except: [ :show ], controller: "users"
  end

  root "zones#index"
end
