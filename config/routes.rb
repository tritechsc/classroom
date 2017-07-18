# frozen_string_literal: true

require "sidekiq/web"
require "staff_constraint"

Rails.application.routes.draw do
  mount Peek::Railtie => "/peek"

  root to: "pages#home"

  get  "/login",  to: "sessions#new",     as: "login"
  post "/logout", to: "sessions#destroy", as: "logout"

  match "/auth/:provider/callback", to: "sessions#create",  via: %i[get post]
  match "/auth/failure",            to: "sessions#failure", via: %i[get post]

  get "/a/:short_key", to: "short_url#assignment_invitation",       as: "assignment_invitation_short"
  get "/g/:short_key", to: "short_url#group_assignment_invitation", as: "group_assignment_invitation_short"

  get "/autocomplete/github_repos", to: "autocomplete#github_repos"

  scope "github", as: "github" do
    constraints user_agent: %r{\AGitHub-Hookshot/\w+\z}, format: "json" do
      post :hooks, to: "hooks#receive"
    end
  end

  resources :assignment_invitations, path: "assignment-invitations", only: [:show] do
    member do
      patch :accept
      get   :setup
      patch :setup_progress
      get   :success
    end
  end

  resources :group_assignment_invitations, path: "group-assignment-invitations", only: [:show] do
    member do
      get   :accept
      patch :accept_assignment
      patch :accept_invitation
      get   :successful_invitation, path: :success
    end
  end

  scope path_names: { edit: "settings" } do
    resources :organizations, path: "classrooms" do
      member do
        get   :invite
        get   :new_assignment, path: "new-assignment"
        get   :setup
        patch :setup_organization
        get   "settings/invitations", to: "organizations#invitation"
        get   "settings/teams",       to: "organizations#show_groupings"

        resource :roster, only: %i[show new create] do
          patch :link
          patch :unlink
        end
      end

      resources :groupings, only: %i[show edit update] do
        resources :groups, only: [:show] do
          member do
            patch "/memberships/:user_id", to: "groups#add_membership", as: "add_membership"
            delete "/memberships/:user_id", to: "groups#remove_membership", as: "remove_membership"
          end
        end
      end

      resources :assignments do
        resources :assignment_repos, only: [:show]
      end

      resources :group_assignments, path: "group-assignments" do
        resources :group_assignment_repos, only: [:show]
      end
    end
  end

  resources :videos, only: [:index]

  namespace :stafftools do
    constraints StaffConstraint.new do
      mount Sidekiq::Web => "/sidekiq"
      mount Flipper::UI.app(GitHubClassroom.flipper) => "/flipper", as: "flipper"
    end

    root "resources#index", as: :root
    get "/resource_search", to: "resources#search"

    resources :users, only: [:show] do
      member do
        post :impersonate
        delete :stop_impersonating
      end
    end

    resources :organizations, path: "classrooms", only: [:show] do
      member do
        delete "/users/:user_id", to: "organizations#remove_user", as: "remove_user"
      end
    end

    resources :repo_accesses, only: [:show]

    resources :assignment_invitations, only: [:show]
    resources :assignment_repos,       only: %i[show destroy]
    resources :assignments,            only: [:show]

    resources :group_assignment_invitations, path: "group-assignment-invitations", only: [:show]
    resources :group_assignment_repos,       path: "group-assignment-repos",       only: %i[show destroy]
    resources :group_assignments,            path: "group-assignments",            only: [:show]

    resources :groupings, only: [:show]
    resources :groups,    only: [:show]
  end
end
