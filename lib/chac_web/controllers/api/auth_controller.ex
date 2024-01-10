defmodule ChacWeb.AuthController do
  use ChacWeb, :controller

  alias Chac.AccountContext
  alias ChacWeb.{Auth, Response}

  @doc """
    Login

    ---| swagger |---
      tag "auth"
      post "/api/auth/login"
      consumes "application/json"
      produces "application/json"
      request_body do
        access_password :string, "Access Passsword", example: "12345678"
        cpf :string, "CPF", example: "123.456.789-11"
      end
      ChacWeb.Response.swagger 200, data: []
    ---| end |---
  """
  def login(conn, params) do
    params
    |> AccountContext.authorize_access()
    |> case do
      {:ok, account} ->
        {:ok, token, _claims} = Auth.encode_and_sign(account)

        %{
          token: token
        }
        |> Response.success(conn)

      {:error, data} ->
        Response.error(data, conn)
    end
  end

  @doc """
    Login

    ---| swagger |---
      tag "auth"
      post "/api/auth/logout"
      consumes "application/json"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      ChacWeb.Response.swagger 200, data: []
    ---| end |---
  """
  def logout(conn, _params) do
    token = conn.private.guardian_default_token

    Auth.revoke(token)
    |> case do
      {:ok, _} -> Response.success(:ok, conn)
      {:error, error} -> Response.error(error, conn)
    end
  end
end
