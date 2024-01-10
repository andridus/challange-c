defmodule ChacWeb.PageController do
  use ChacWeb, :controller

  @doc """
    Health Check

    ---| swagger |---
      tag "Health Check"
      get "/"
      produces "application/json"
      ChacWeb.Response.swagger 200, data: %{success: true}
    ---| end |---
  """
  def health_check(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    json(conn, %{success: true, swagger: "/swagger"})
  end
end
