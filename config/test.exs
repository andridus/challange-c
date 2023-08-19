import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
# Configure your database
database_url_test =
  System.get_env("DATABASE_URL_TEST") ||
    raise """
    environment variable DATABASE_URL_TEST is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :cumbuca, Cumbuca.Repo,
  url: "#{database_url_test}#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cumbuca, CumbucaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "z+mFuL39PzpBWfxRCneevXbZLms0O4XFNSMJwSZOgR+yIsY3P06eec14waEPy5AD",
  server: false

# In test we don't send emails.
config :cumbuca, Cumbuca.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
