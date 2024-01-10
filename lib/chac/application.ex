defmodule Chac.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Chac.Worker.AccountsSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ChacWeb.Telemetry,
      # Start the Ecto repository
      Chac.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Chac.PubSub},
      # Start Finch
      {Finch, name: Chac.Finch},
      # Start the Endpoint (http/https)
      ChacWeb.Endpoint
      # Start a worker by calling: Chac.Worker.start_link(arg)
      # {Chac.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options

    opts = [strategy: :one_for_one, name: Chac.Supervisor]
    _sup = Supervisor.start_link(children, opts)

    ## start accounts supervisor
    AccountsSupervisor.start_link()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChacWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
