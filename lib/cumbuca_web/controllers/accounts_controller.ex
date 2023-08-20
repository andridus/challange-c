defmodule CumbucaWeb.AccountsController do
  use CumbucaWeb, :controller

  alias Cumbuca.AccountsContext
  alias CumbucaWeb.{Auth, Response}

  @doc """
    Create account

    ---| swagger |---
      tag "accounts"
      post "/api/accounts"
      consumes "application/json"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      request_body do
        first_name :string, "First Name", example: "Joe"
        last_name :string, "Last Name", example: "Doe"
        cpf :string, "CPF", example: "123.456.789-11"
        balance :integer, "Initial Balance", example: 100_00
      end
      CumbucaWeb.Response.swagger 200, data: Cumbuca.Core.Account._swagger_schema_(:basic)
    ---| end |---
  """
  def create(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> AccountsContext.create_account()
    |> Response.pipe(conn)
  end

  @doc """
    Update account

    ---| swagger |---
      tag "accounts"
      put "/api/accounts/{account_id}"
      consumes "application/json"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      parameters do
        account_id :path, :string, "Account id", required: true
      end
      request_body do
        first_name :string, "First Name", example: "Joe"
        last_name :string, "Last Name", example: "Doe"
      end
      CumbucaWeb.Response.swagger 200, data: Cumbuca.Core.Account._swagger_schema_(:basic)
    ---| end |---
  """
  def update(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> AccountsContext.update_account()
    |> Response.pipe(conn)
  end

  @doc """
    Get all accounts

    ---| swagger |---
      tag "accounts"
      get "/api/accounts"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      CumbucaWeb.Response.swagger 200, data: [Cumbuca.Core.Account._swagger_schema_(:basic)]
    ---| end |---
  """
  def all(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> AccountsContext.all()
    |> Response.pipe(conn)
  end

  @doc """
    Get one account by id

    ---| swagger |---
      tag "accounts"
      get "/api/accounts/{account_id}"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      parameters do
        account_id :path, :string, "Account id", required: true
      end
      CumbucaWeb.Response.swagger 200, Cumbuca.Core.Account._swagger_schema_(:basic)
    ---| end |---
  """
  def one(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> AccountsContext.one()
    |> Response.pipe(conn)
  end

  @doc """
    Delete account by id

    ---| swagger |---
      tag "accounts"
      delete "/api/accounts/{account_id}"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      parameters do
        account_id :path, :string, "Account id", required: true
      end
      CumbucaWeb.Response.swagger 200, data: Cumbuca.Core.Account._swagger_schema_(:basic)
    ---| end |---
  """
  def delete(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> AccountsContext.delete()
    |> Response.pipe(conn)
  end
end
