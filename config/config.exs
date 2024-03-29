# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :chac, :swagger,
  host: "localhost",
  port: 4000,
  scheme: "http",
  base_module: "Chac",
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: ChacWeb.Router
    ]
  }

config :chac, swagger_json_library: Jason

config :chac, ecto_repos: [Chac.Repo]
config :chac, Chac.Repo, migration_primary_key: [type: :binary_id]

config :chac, ChacWeb.Auth,
  issuer: "cumbuca",
  secret_key: "rqvarp+9WBlj4mywg3W3Bz0iSvS0m3aE5FCl9MOTAuHddiwYxjMUXXA+6/T2W9Fh"

config :bee, :repo, Chac.Repo

# Configures the endpoint
config :chac, ChacWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: ChacWeb.ErrorHTML, json: ChacWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Chac.PubSub,
  live_view: [signing_salt: "tqVVI83S"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :chac, Chac.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
