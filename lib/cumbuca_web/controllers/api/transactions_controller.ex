defmodule CumbucaWeb.TransactionsController do
  use CumbucaWeb, :controller

  alias Cumbuca.TransactionContext
  alias CumbucaWeb.{Auth, Response}

  @doc """
    Create transaction

    ---| swagger |---
      tag "transactions"
      post "/api/transactions"
      consumes "application/json"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      request_body do
        payer_id :uuid, "Id of payer account", example: Ecto.UUID.generate()
        receiver_id :uuid, "Id of receiver account", example: Ecto.UUID.generate()
        amount :integer, "Amount to transfer", example: 1000
      end
      CumbucaWeb.Response.swagger 200, data: Cumbuca.Core.Transaction._swagger_schema_(:basic)
    ---| end |---
  """
  def create(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> TransactionContext.create_transaction()
    |> Response.pipe(conn)
  end

  @doc """
    Cancel pending transaction

    ---| swagger |---
      tag "transactions"
      post "/api/transactions/{transaction_id}/cancel"
      consumes "application/json"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      parameters do
        transaction_id :path, :string, "Transaction id", required: true
      end
      CumbucaWeb.Response.swagger 200, data: Cumbuca.Core.Transaction._swagger_schema_(:basic)
    ---| end |---
  """
  def cancel(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> TransactionContext.cancel_transaction()
    |> Response.pipe(conn)
  end

  @doc """
    Refund transaction

    ---| swagger |---
      tag "transactions"
      post "/api/transactions/{transaction_id}/refund"
      consumes "application/json"
      produces "application/json"
      parameter "authorization", :header, :string, "Access Token"
      parameters do
        transaction_id :path, :string, "Transaction id", required: true
      end
      CumbucaWeb.Response.swagger 200, data: Cumbuca.Core.Transaction._swagger_schema_(:basic)
    ---| end |---
  """
  def refund(conn, params) do
    params
    |> Map.put("authed", Auth.get_user(conn))
    |> Map.put("permission", Auth.get_permission(conn))
    |> TransactionContext.refund_transaction()
    |> Response.pipe(conn)
  end
end
