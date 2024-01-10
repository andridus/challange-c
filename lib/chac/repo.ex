defmodule Chac.Repo do
  use Ecto.Repo,
    otp_app: :chac,
    adapter: Ecto.Adapters.Postgres
end
