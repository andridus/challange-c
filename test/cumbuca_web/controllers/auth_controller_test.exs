defmodule CumbucaWeb.AuthControllerTest do
  use CumbucaWeb.ConnCase

  describe "CRUD Accounts" do
    @access_password "12345678"
    setup do
      Factory.Account.create()
      |> Factory.Account.set_access_password(@access_password)
      |> Factory.Account.set_transaction_password("1234")
    end

    test "POST /api/auth/login", ctx do
      account = ctx[:account]
      account_id = account.id

      params0 = %{
        cpf: account.cpf,
        access_password: @access_password
      }

      response = post(anonymous_conn(), ~p"/api/auth/login", params0) |> get_resp_body()
      assert %{"data" => %{"token" => token}} = response

      response =
        get(authed_conn(token), ~p"/api/accounts/#{account.id}", params0) |> get_resp_body()

      assert %{"data" => %{"id" => ^account_id}} = response
    end

    test "POST /api/auth/login - invalid account", ctx do
      account = ctx[:account]

      params0 = %{
        cpf: account.cpf,
        access_password: "123456789"
      }

      response = post(anonymous_conn(), ~p"/api/auth/login", params0) |> get_resp_body()
      assert %{"message" => "cpf_or_password_invalid"} = response
    end

    test "POST /api/auth/logout", ctx do
      account = ctx[:account]
      account_id = account.id

      params0 = %{
        cpf: account.cpf,
        access_password: @access_password
      }

      response = post(anonymous_conn(), ~p"/api/auth/login", params0) |> get_resp_body()
      assert %{"data" => %{"token" => token}} = response

      response =
        get(authed_conn(token), ~p"/api/accounts/#{account.id}", params0) |> get_resp_body()

      assert %{"data" => %{"id" => ^account_id}} = response

      response = post(authed_conn(token), ~p"/api/auth/logout", %{}) |> get_resp_body()
      assert %{"message" => "ok"} = response
    end

    test "POST /api/auth/logout - unauthenticated" do
      response = post(anonymous_conn(), ~p"/api/auth/logout", %{}) |> get_resp_body()
      assert %{"message" => "unauthenticated"} = response
    end
  end
end
