Rails.application.routes.draw do
  # ルートパス
  root "dashboard#index"

  # Devise（ログイン・登録・ログアウト）
  devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations" }

  # ゲストログイン（devise_scope)
  devise_scope :user do
    post "guest_sign_in", to: "users/sessions#guest_sign_in"
  end

  # 経費申請
  resources :expense_reports do
    # 提出アクション（PATCHメソッド、/expense_reports/:id/submit）
    member do
      patch :submit
      get   :self_check
    end
    # 申請アイテム
    resources :expense_items, only: %i[new create edit update destroy]
  end

  # OCR
  resources :ocr, only: %i[create]

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
