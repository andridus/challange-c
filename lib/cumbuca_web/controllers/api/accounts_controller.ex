defmodule CumbucaWeb.AccountsController do
  use CumbucaWeb, :controller

  alias Cumbuca.{AccountContext, ConsolidationContext}
  alias CumbucaWeb.{Auth, Response}

  @doc """
    Create account

    ---| swagger |---
      tag "accounts"
      post "/api/accounts"
      consumes "application/json"
      produces "application/json"
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
    |> AccountContext.create_account()
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
    |> AccountContext.update_account()
    |> Response.pipe(conn)
  end

  @doc """
    Update access password

    ---| swagger |---
      tag "accounts"
      patch "/api/accounts/{account_id}/access-password"
      consumes "application/json"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      parameters do
        account_id :path, :string, "Account id", required: true
      end
      request_body do
        access_password :string, "Access Password", example: "12345678"
        access_password_repeat :string, "Access Password Repeat", example: "12345678"
      end
      CumbucaWeb.Response.swagger 200, data: "access_password_updated"
    ---| end |---
  """
  def patch_access_password(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> AccountContext.patch_access_password()
    |> Response.pipe(conn)
  end

  @doc """
    Update transaction password

    ---| swagger |---
      tag "accounts"
      patch "/api/accounts/{account_id}/transaction-password"
      consumes "application/json"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      parameters do
        account_id :path, :string, "Account id", required: true
      end
      request_body do
        transaction_password :string, "Transaction Password", example: "12345678"
        transaction_password_repeat :string, "Transaction Password Repeat", example: "12345678"
      end
      CumbucaWeb.Response.swagger 200, data: "transaction_password_updated"
    ---| end |---
  """
  def patch_transaction_password(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> AccountContext.patch_transaction_password()
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
    |> AccountContext.all()
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
    |> AccountContext.one()
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
    |> AccountContext.delete()
    |> Response.pipe(conn)
  end

  @doc """
    Get consolidations from account

    ---| swagger |---
      tag "accounts"
      get "/api/accounts/{account_id}/consolidations"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      parameters do
        account_id :path, :string, "Account id", required: true
        from :query, :date, "Date from"
        to :query, :date, "Date to"
      end
      CumbucaWeb.Response.swagger 200, data: [Cumbuca.Core.Consolidation._swagger_schema_(:account_owner)]
    ---| end |---
  """
  def all_consolidations(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> ConsolidationContext.all_by_account()
    |> Response.pipe(conn)
  end
end
