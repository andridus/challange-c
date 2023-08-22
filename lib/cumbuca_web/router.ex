defmodule CumbucaWeb.Router do
  use CumbucaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CumbucaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug CumbucaWeb.Auth.Pipeline
  end

  pipeline :authed do
    plug CumbucaWeb.Auth.Pipeline
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", CumbucaWeb do
    pipe_through [:api]

    get "/", PageController, :health_check
  end

  scope "/api", CumbucaWeb do
    pipe_through [:api]

    ## auth
    scope "/auth" do
      post "/login", AuthController, :login

      scope "/" do
        pipe_through [:authed]
        post "/logout", AuthController, :logout
      end
    end

    ## account
    post "/accounts", AccountsController, :create
    patch "/accounts/:account_id/access-password", AccountsController, :patch_access_password

    scope "/" do
      pipe_through [:authed]
      get "/accounts", AccountsController, :all
      get "/accounts/:account_id", AccountsController, :one
      get "/accounts/:account_id/consolidations", AccountsController, :all_consolidations
      get "/accounts/:account_id/balance", AccountsController, :show_balance
      put "/accounts/:account_id", AccountsController, :update

      patch "/accounts/:account_id/transaction-password",
            AccountsController,
            :patch_transaction_password

      delete "/accounts/:account_id", AccountsController, :delete
    end

    ## transactions
    scope "/" do
      pipe_through [:authed]

      post "/transactions", TransactionsController, :create
      post "/transactions/:transaction_id/cancel", TransactionsController, :cancel
      post "/transactions/:transaction_id/refund", TransactionsController, :refund
      get "/transactions/:transaction_id", TransactionsController, :one
    end
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "Cumbuca"
      }
    }
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:cumbuca, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CumbucaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/swagger" do
      forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :cumbuca, swagger_file: "swagger.json"
    end
  end
end
