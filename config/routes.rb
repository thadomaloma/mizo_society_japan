Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  root "dashboard#index"
  get "search", to: "searches#index", as: :global_search
  get "membership_payments", to: redirect("/payments"), as: nil
  get "membership_payments/:id", to: redirect("/payments/%{id}"), as: nil
  get "membership_payments/:id/success", to: redirect("/payments/%{id}"), as: nil
  get "membership_payments/:id/cancel", to: redirect("/payments/%{id}"), as: nil
  get "admin/membership_payments", to: redirect("/admin/payments"), as: nil
  get "admin/membership_payments/new", to: redirect("/admin/payments/new"), as: nil
  get "admin/membership_payments/:id", to: redirect("/admin/payments/%{id}"), as: nil
  get "admin/membership_payments/:id/edit", to: redirect("/admin/payments/%{id}/edit"), as: nil
  resources :notifications, only: [ :index ] do
    member do
      patch :mark_as_read
    end

    collection do
      patch :mark_all_as_read
    end
  end
  resources :membership_payments, path: "payments", only: [ :index, :show ] do
    collection do
      post :start
    end

    member do
      post :checkout
      patch :submit_transfer
      get :success
      get :cancel
    end
  end
  resources :welfare_cases, only: [ :index, :show, :new, :create, :edit, :update ]
  get "/documents", to: redirect("/letters"), as: nil
  get "/documents/new", to: redirect("/letters/new"), as: nil
  get "/documents/:id", to: redirect("/letters/%{id}"), as: nil
  get "/documents/:id/edit", to: redirect("/letters/%{id}/edit"), as: nil

  resources :documents, path: "letters" do
    collection do
      post :official_letter_template
    end

    member do
      get :download
      get :download_letter
      patch :publish
      patch :archive
    end
  end
  resources :announcements do
    member do
      patch :publish
      patch :archive
    end
  end
  resources :events do
    member do
      patch :publish
      patch :complete
      patch :cancel
      post :rsvp
      patch :withdraw_rsvp
      get :calendar
    end

    resources :photos, only: [ :destroy ], controller: "event_photos"
  end
  resources :meeting_minutes do
    member do
      get :download
      get :export_pdf
      patch :publish
    end
  end
  resource :profile, only: [ :show, :edit, :update ] do
    get :setup
    patch :complete_setup, action: :create_setup
  end

  namespace :webhooks do
    post "stripe", to: "stripe#create"
  end

  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"
    resources :membership_plans
    resources :membership_plan_types, except: [ :show ]
    resources :event_categories, except: [ :show ]
    resources :document_categories, except: [ :show ]
    resources :membership_payments, path: "payments" do
      member do
        patch :approve
        patch :reject
      end
    end
    resources :finance_categories
    resources :finance_transactions do
      member do
        patch :approve
        patch :reject
      end
    end
    resource :payment_settings, path: "bank_details", only: [ :show, :update ]
    resources :welfare_cases, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
      member do
        patch :assign
        patch :resolve
        patch :reject
      end

      resources :welfare_notes, except: [ :index, :show, :new ]
    end
    resources :welfare_categories, except: [ :show ]
    resources :welfare_attachments, only: [ :destroy ]
    resources :reports, only: [ :index ] do
      collection do
        get :finance
        get :members
        get :events
        get :welfare
      end
    end
    resource :settings, only: [ :show, :update ]
    get "permissions", to: "user_roles#permissions"
    resources :user_roles, only: [ :index, :new, :create, :edit, :update ] do
      member do
        patch :deactivate
        patch :reactivate
      end
    end
    resources :audit_logs, only: [ :index, :show ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
