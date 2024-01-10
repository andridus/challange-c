defmodule ChacWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ChacWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  import Plug.Conn

  using do
    quote do
      # The default endpoint for testing
      @endpoint ChacWeb.Endpoint

      use ChacWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ChacWeb.ConnCase
    end
  end

  def authed_conn(token) when is_bitstring(token) do
    Phoenix.ConnTest.build_conn()
    |> put_req_header("authorization", "Bearer #{token}")
  end

  def authed_conn(%{authed: account}), do: authed_conn(account)

  def authed_conn(%{"id" => id} = account),
    do:
      Map.to_list(account)
      |> Enum.map(fn {x, y} -> {String.to_atom(x), y} end)
      |> Map.new()
      |> authed_conn()

  def authed_conn(account) do
    {_, token, _} = account |> ChacWeb.Auth.encode_and_sign()

    Phoenix.ConnTest.build_conn()
    |> put_req_header("authorization", "Bearer #{token}")
  end

  def anonymous_conn do
    Phoenix.ConnTest.build_conn()
  end

  def get_resp_body(conn), do: conn |> Map.get(:resp_body) |> Jason.decode!()

  setup tags do
    Chac.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
