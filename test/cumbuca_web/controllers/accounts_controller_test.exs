defmodule CumbucaWeb.AccountsControllerTest do
  use CumbucaWeb.ConnCase

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

      post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      ## Second account
      params1 = %{
        first_name: "Jane",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      post(anonymous_conn(), ~p"/api/accounts", params1) |> get_resp_body()

      response = get(anonymous_conn(), ~p"/api/accounts") |> get_resp_body()

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

      assert %{"data" => %{"id" => id}} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      response = get(anonymous_conn(), ~p"/api/accounts/#{id}") |> get_resp_body()

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

      assert %{"data" => %{"id" => id}} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      # Update First account
      params0 = %{
        first_name: "Jonh"
      }

      assert %{"data" => %{"id" => id, "first_name" => "Jonh"}} =
               put(anonymous_conn(), ~p"/api/accounts/#{id}", params0) |> get_resp_body()

      response = get(anonymous_conn(), ~p"/api/accounts/#{id}") |> get_resp_body()

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
               put(anonymous_conn(), ~p"/api/accounts/#{id}", params1) |> get_resp_body()

      response = get(anonymous_conn(), ~p"/api/accounts/#{id}") |> get_resp_body()

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
      id = Ecto.UUID.generate()

      params0 = %{
        first_name: "Jonh"
      }

      assert %{"message" => "account_not_found"} =
               put(anonymous_conn(), ~p"/api/accounts/#{id}", params0) |> get_resp_body()
    end

    test "DELETE /api/accounts - show all accounts" do
      # First account
      params0 = %{
        first_name: "Joe",
        last_name: "Doe",
        cpf: Brcpfcnpj.cpf_generate(),
        balance: 0
      }

      assert %{"data" => %{"id" => id}} =
               post(anonymous_conn(), ~p"/api/accounts", params0) |> get_resp_body()

      response = delete(anonymous_conn(), ~p"/api/accounts/#{id}") |> get_resp_body()

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

      response = get(anonymous_conn(), ~p"/api/accounts/#{id}") |> get_resp_body()
      assert %{"message" => "account_not_found"} = response
    end

    ## TODO: Test for update password
    ## TODO: Test for deactivate account
    ## TODO: Test to close account
    ## TODO: Test to cant delete account, but set CLOSED
  end
end
