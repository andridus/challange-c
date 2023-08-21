defmodule CumbucaWeb.TransactionsControllerTest do
  use CumbucaWeb.ConnCase

  alias Cumbuca.Core.{Transaction}

  describe "Transactions - with insuficient funds" do
    @transaction_password "1234"
    setup do
      Factory.Account.create()
      |> Factory.Account.set_access_password("12345678")
      |> Factory.Account.set_transaction_password(@transaction_password)
      |> Factory.Account.create(%{}, tag: :receiver)
      |> Factory.Account.set_access_password("12345678", tag: :receiver)
      |> Factory.Account.set_transaction_password(@transaction_password, tag: :receiver)
    end

    test "POST /api/transactions - the first error transaction", ctx do
      payer = ctx.account
      receiver = ctx.receiver
      payer_id = payer.id
      receiver_id = receiver.id

      ## Validate required params
      params = %{
        payer_id: payer_id,
        receiver_id: receiver_id,
        amount: 10_00,
        transaction_password: @transaction_password
        }
      response = post(authed_conn(payer), ~p"/api/transactions", params) |> get_resp_body()
      assert %{
               "details" => %{ "amount" => "insuficient_funds"}
              } = response
    end
  end

  describe "Transactions - success" do
    @transaction_password "1234"
    setup do

      %{}
      |> Factory.Account.create(%{initial_balance: 100_00})
      |> Factory.Account.set_access_password("12345678")
      |> Factory.Account.set_transaction_password(@transaction_password)
      |> Factory.Account.create(%{}, tag: :receiver)
      |> Factory.Account.set_access_password("12345678", tag: :receiver)
      |> Factory.Account.set_transaction_password(@transaction_password, tag: :receiver)
    end

    test "POST /api/transactions - the first transaction", ctx do
      payer = ctx.account
      receiver = ctx.receiver
      payer_id = payer.id
      receiver_id = receiver.id

      ## Validate required params
      params0 = %{
        payer_id: payer_id,
        receiver_id: receiver_id,
        amount: 10_00
        }
      assert %{"message" => "param_transaction_password_not_found"} = post(authed_conn(payer), ~p"/api/transactions", params0) |> get_resp_body()

      ## Validate required params
      params1 = Map.merge(params0, %{ transaction_password: "12345" })

      assert %{"message" => "invalid_password"} = post(authed_conn(payer), ~p"/api/transactions", params1) |> get_resp_body()

      ## Validate required params
      params2 = Map.merge(params0, %{ transaction_password: @transaction_password })
      response = post(authed_conn(payer), ~p"/api/transactions", params2) |> get_resp_body()
      assert %{
               "data" => %{
                 "id" => id,
                 "status" => "PENDING",
                 "completed_at" => nil,
               }
             } = response

      assert {:ok, %{
        amount: 10_00,
        status: :PENDING,
        payer_id: ^payer_id,
        receiver_id: ^receiver_id}
        } = Transaction.Api.get(id)
    end
    test "POST /api/transactions/{id}/cancel", ctx do
      payer = ctx.account
      receiver = ctx.receiver
      payer_id = payer.id
      receiver_id = receiver.id

      ## Validate required params
      params = %{
        payer_id: payer_id,
        receiver_id: receiver_id,
        amount: 10_00,
        transaction_password: @transaction_password
        }
      response = post(authed_conn(payer), ~p"/api/transactions", params) |> get_resp_body()
      assert %{
               "data" => %{
                 "id" => id,
                 "status" => "PENDING",
                 "completed_at" => nil,
               }
             } = response

      assert {:ok, %{
        amount: 10_00,
        status: :PENDING,
        payer_id: ^payer_id,
        receiver_id: ^receiver_id}
        } = Transaction.Api.get(id)

      ## check the permission forroute
      assert %{"message" => "operation_not_allowed_for_this_user"} = post(authed_conn(receiver), ~p"/api/transactions/#{id}/cancel") |> get_resp_body()

      response = post(authed_conn(payer), ~p"/api/transactions/#{id}/cancel") |> get_resp_body()
      assert %{
               "data" => %{
                 "id" => id,
                 "status" => "CANCELED",
                 "completed_at" => nil,
               }
             } = response
      assert {:ok, %{
        amount: 10_00,
        status: :CANCELED,
        payer_id: ^payer_id,
        receiver_id: ^receiver_id,
        canceled?: true

        }
        } = Transaction.Api.get(id)
    end
  end
end
