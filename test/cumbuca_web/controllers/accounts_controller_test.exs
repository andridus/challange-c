defmodule CumbucaWeb.AccountsControllerTest do
  use CumbucaWeb.ConnCase

  alias Cumbuca.Core.Account

  describe "CRUD Accounts" do
    setup do
      :ok
    end

    test "POST /api/accounts - check not found params" do
      ## Validate required params
      params = %{last_name: "Joe"}

      assert %{"message" => "param_first_name_not_found"} =
               post(anonymous_conn(), ~p"/api/accounts", params) |> get_resp_body()

      params = %{first_name: "Joe"}

      assert %{"message" => "param_last_name_not_found"} =
               post(anonymous_conn(), ~p"/api/accounts", params) |> get_resp_body()

      params = %{
        first_name: "Joe",
        last_name: "Doe"
      }

      assert %{"message" => "param_cpf_not_found"} =
               post(anonymous_conn(), ~p"/api/accounts", params) |> get_resp_body()

      params = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate()
      }

      assert %{"message" => "param_balance_not_found"} =
               post(anonymous_conn(), ~p"/api/accounts", params) |> get_resp_body()

      params = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      response = post(anonymous_conn(), ~p"/api/accounts", params) |> get_resp_body()

      assert %{
               "data" => %{
                 "active?" => false,
                 "id" => _,
                 "first_name" => "Joe",
                 "last_name" => "Doe",
                 "status" => "INACTIVE",
                 "inserted_at" => _,
                 "updated_at" => _
               }
             } = response

      account_fields = response["data"]
      ## shouldn't be virtual fields
      refute account_fields["__access_password__"]
      refute account_fields["__action__"]
      refute account_fields["__transaction_password__"]

      ## shouldn't be public fields
      refute account_fields["cpf"]
      refute account_fields["access_blocked?"]
      refute account_fields["access_blocked_at"]
      refute account_fields["attempts_access"]
      refute account_fields["closed?"]
      refute account_fields["deactivated_at"]
      refute account_fields["initial_balance"]

      ## shouldn't be password fields
      refute account_fields["access_password_hash"]
      refute account_fields["transaction_password_hash"]
    end

    test "POST /api/accounts - can't create with same cpf" do
      # First account
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      response = post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      assert %{"data" => %{"id" => id1}} = response

      ## try create second account with same cpf
      params1 = %{
        first_name: "Jane",
        last_name: "Doe",
        cpf: params0.cpf,
        balance: 0
      }

      response = post(anonymous_conn(), ~p"/api/accounts", params1) |> get_resp_body()

      assert %{"details" => %{"cpf" => "has already been taken"}} = response

      ## create second account with other cpf
      params2 = %{
        first_name: "Jane",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      response = post(anonymous_conn(), ~p"/api/accounts", params2) |> get_resp_body()
      assert %{"data" => %{"id" => id2}} = response
      assert id1 != id2
    end

    test "GET /api/accounts - show all accounts" do
      # First account
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      ## Second account
      params1 = %{
        first_name: "Jane",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      post(anonymous_conn(), ~p"/api/accounts", params1)

      response = get(authed_conn(account), ~p"/api/accounts") |> get_resp_body()

      assert %{"data" => [one | _] = data} = response
      assert 2 = Enum.count(data)
      ## shouldn't be public fields
      refute one["cpf"]
      refute one["access_blocked?"]
      refute one["access_blocked_at"]
      refute one["attempts_access"]
      refute one["closed?"]
      refute one["deactivated_at"]
      refute one["initial_balance"]
    end

    test "GET /api/accounts/{account_id} - show one account" do
      # First account
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => %{"id" => id} = account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      assert %{"message" => "unauthenticated"} =
               get(anonymous_conn(), ~p"/api/accounts/#{id}") |> get_resp_body()

      response = get(authed_conn(account), ~p"/api/accounts/#{id}") |> get_resp_body()

      assert %{
               "data" =>
                 %{
                   "active?" => false,
                   "id" => _,
                   "first_name" => "Joe",
                   "last_name" => "Doe",
                   "status" => "INACTIVE",
                   "inserted_at" => _,
                   "updated_at" => _
                 } = account
             } = response

      ## shouldn't be public fields
      refute account["cpf"]
      refute account["access_blocked?"]
      refute account["access_blocked_at"]
      refute account["attempts_access"]
      refute account["closed?"]
      refute account["deactivated_at"]
      refute account["initial_balance"]
    end

    test "PUT /api/accounts/{account_id} - udpate first and last name" do
      # First account
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => %{"id" => id} = account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      # Update First account
      params0 = %{
        first_name: "Jonh"
      }

      assert %{"message" => "unauthenticated"} =
               put(anonymous_conn(), ~p"/api/accounts/#{id}", params0) |> get_resp_body()

      assert %{"data" => %{"id" => id, "first_name" => "Jonh"}} =
               put(authed_conn(account), ~p"/api/accounts/#{id}", params0) |> get_resp_body()

      response = get(authed_conn(account), ~p"/api/accounts/#{id}") |> get_resp_body()

      assert %{
               "data" => %{
                 "active?" => false,
                 "id" => _,
                 "first_name" => "Jonh",
                 "last_name" => "Doe",
                 "status" => "INACTIVE",
                 "inserted_at" => _,
                 "updated_at" => _
               }
             } = response

      # Update First account
      params1 = %{
        last_name: "Updated"
      }

      assert %{"data" => %{"id" => id, "last_name" => "Updated"}} =
               put(authed_conn(account), ~p"/api/accounts/#{id}", params1) |> get_resp_body()

      response = get(authed_conn(account), ~p"/api/accounts/#{id}") |> get_resp_body()

      assert %{
               "data" => %{
                 "active?" => false,
                 "id" => _,
                 "first_name" => "Jonh",
                 "last_name" => "Updated",
                 "status" => "INACTIVE",
                 "inserted_at" => _,
                 "updated_at" => _
               }
             } = response
    end

    test "PUT /api/accounts/{account_id} - try update account that don't exists" do
      # First account
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      id = Ecto.UUID.generate()

      params0 = %{
        first_name: "Jonh"
      }

      assert %{"message" => "unauthenticated"} =
               put(anonymous_conn(), ~p"/api/accounts/#{id}", params0) |> get_resp_body()

      assert %{"message" => "account_not_found"} =
               put(authed_conn(account), ~p"/api/accounts/#{id}", params0) |> get_resp_body()
    end

    test "DELETE /api/accounts/{id}" do
      # First account
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => %{"id" => id} = account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      response = delete(authed_conn(account), ~p"/api/accounts/#{id}") |> get_resp_body()

      assert %{
               "data" => %{
                 "active?" => false,
                 "id" => _,
                 "first_name" => "Joe",
                 "last_name" => "Doe",
                 "status" => "CLOSED",
                 "inserted_at" => _,
                 "updated_at" => _
               }
             } = response

      response = get(authed_conn(account), ~p"/api/accounts/#{id}") |> get_resp_body()

      assert %{
               "data" => %{
                 "active?" => false,
                 "id" => _,
                 "first_name" => "Joe",
                 "last_name" => "Doe",
                 "status" => "CLOSED",
                 "inserted_at" => _,
                 "updated_at" => _
               }
             } = response
    end

    test "PATCH /api/accounts/{account_id}/access-password - creates a access password" do
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => %{"id" => id}} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      # Update password
      params1 = %{
        access_password: "12345678",
        repeat_access_password: "12345678"
      }

      response =
        patch(anonymous_conn(), ~p"/api/accounts/#{id}/access-password", params1)
        |> get_resp_body()

      assert %{"data" => "access_password_updated"} = response

      # Check account was activated
      {:ok, %{access_password_hash: hash, active?: true}} = Account.Api.get(id)
      refute is_nil(hash)
    end

    test "PATCH /api/accounts/{account_id}/access-password - creation fail" do
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => %{"id" => id} = account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      # Password don`t macht
      params1 = %{
        access_password: "12345678",
        repeat_access_password: "123456789"
      }

      response =
        patch(authed_conn(account), ~p"/api/accounts/#{id}/access-password", params1)
        |> get_resp_body()

      assert %{"message" => "password_dont_match"} = response

      # missing repeat_access_password field
      params1 = %{
        access_password: "12345"
      }

      response =
        patch(authed_conn(account), ~p"/api/accounts/#{id}/access-password", params1)
        |> get_resp_body()

      assert %{"message" => "param_repeat_access_password_not_found"} = response

      # missing access_password field
      params1 = %{
        repeat_access_password: "12345"
      }

      response =
        patch(authed_conn(account), ~p"/api/accounts/#{id}/access-password", params1)
        |> get_resp_body()

      assert %{"message" => "param_access_password_not_found"} = response
    end

    test "PATCH /api/accounts/{account_id}/transaction-password - creates a transaction password" do
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => %{"id" => id} = account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      # Update password
      params1 = %{
        transaction_password: "1234",
        repeat_transaction_password: "1234"
      }

      response =
        patch(authed_conn(account), ~p"/api/accounts/#{id}/transaction-password", params1)
        |> get_resp_body()

      assert %{"data" => "transaction_password_updated"} = response

      {:ok, %{transaction_password_hash: hash, active?: true}} = Account.Api.get(id)
      refute is_nil(hash)
      assert {:ok, "1234"} = Base.decode64(hash)
    end

    test "PATCH /api/accounts/{account_id}/transaction-password - creation fail" do
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => %{"id" => id} = account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      # Password don`t macht
      params1 = %{
        transaction_password: "1234",
        repeat_transaction_password: "12345"
      }

      response =
        patch(authed_conn(account), ~p"/api/accounts/#{id}/transaction-password", params1)
        |> get_resp_body()

      assert %{"message" => "password_dont_match"} = response

      # Password with not specified length
      params1 = %{
        transaction_password: "12345",
        repeat_transaction_password: "12345"
      }

      response =
        patch(authed_conn(account), ~p"/api/accounts/#{id}/transaction-password", params1)
        |> get_resp_body()

      assert %{"message" => "password_length_should_be_four"} = response

      # missing repeat_transaction_password field
      params1 = %{
        transaction_password: "12345"
      }

      response =
        patch(authed_conn(account), ~p"/api/accounts/#{id}/transaction-password", params1)
        |> get_resp_body()

      assert %{"message" => "param_repeat_transaction_password_not_found"} = response

      # missing transaction_password field
      params1 = %{
        repeat_transaction_password: "12345"
      }

      response =
        patch(authed_conn(account), ~p"/api/accounts/#{id}/transaction-password", params1)
        |> get_resp_body()

      assert %{"message" => "param_transaction_password_not_found"} = response
    end

    test "PUT /api/accounts/{account_id}/consolidations" do
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 10_00
      }

      assert %{"data" => %{"id" => id} = account} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      query_params =
        %{
          from: Date.utc_today() |> Date.add(-2),
          to: Date.utc_today() |> Date.add(-1)
        }
        |> URI.encode_query()

      response =
        get(authed_conn(account), "/api/accounts/#{id}/consolidations?#{query_params}")
        |> get_resp_body()

      assert %{"data" => []} = response

      response =
        get(authed_conn(account), "/api/accounts/#{id}/consolidations") |> get_resp_body()

      assert %{"data" => [%{"id" => _id, "amount" => 10_00, "operation" => "CREDIT"}]} = response
    end
  end
end
