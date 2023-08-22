defmodule Cumbuca.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Cumbuca.Worker.AccountsSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CumbucaWeb.Telemetry,
      # Start the Ecto repository
      Cumbuca.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Cumbuca.PubSub},
      # Start Finch
      {Finch, name: Cumbuca.Finch},
      # Start the Endpoint (http/https)
      CumbucaWeb.Endpoint
      # Start a worker by calling: Cumbuca.Worker.start_link(arg)
      # {Cumbuca.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options

    opts = [strategy: :one_for_one, name: Cumbuca.Supervisor]
    sup = Supervisor.start_link(children, opts)

    ## start accounts supervisor
    AccountsSupervisor.start_link()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CumbucaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
