defmodule Cumbuca.AccountContext do
  @moduledoc """
    Context of account functions
  """
  alias Cumbuca.Core.Account
  alias Cumbuca.Utils
  import Happy

  @doc """
    Register an account
    params:
      - authed
      - permission
      - first_name
      - last_name
      - cpf
      - balance
  """
  def create_account(params) do
    _authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic

    happy_path do
      # required params
      @param_first_name {:ok, first_name} = Utils.get_param(params, "first_name")
      @param_last_name {:ok, last_name} = Utils.get_param(params, "last_name")
      @param_cpf {:ok, cpf} = Utils.get_param(params, "cpf")
      @param_balance {:ok, balance} = Utils.get_param(params, "balance")

      insert_params = %{
        first_name: first_name,
        last_name: last_name,
        initial_balance: balance,
        cpf: cpf,
        __action__: :CREATE
      }

      Account.Api.insert(insert_params)
      |> Utils.visible_fields(permission)
    else
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    Update an account
    params:
      - authed
      - permission
      - first_name
      - last_name
  """
  def update_account(params) do
    _authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic
    first_name = Access.get(params, "first_name")
    last_name = Access.get(params, "last_name")

    happy_path do
      # required params
      @param_account_id {:ok, account_id} = Utils.get_param(params, "account_id")
      @account {:ok, true} = Account.Api.exists(account_id)

      update_params =
        %{
          id: account_id,
          first_name: first_name,
          last_name: last_name,
          __action__: :UPDATE
        }
        |> Utils.remove_nil_fields()

      Account.Api.update(update_params)
      |> Utils.visible_fields(permission)
    else
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {:account, {:error, false}} -> {:error, "account_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    Update access password for account
    params:
      - authed
      - permission
      - access_password
      - repeat_access_password
  """
  def patch_access_password(params) do
    _authed = Access.get(params, "authed")
    _permission = Access.get(params, "permission") || :basic

    happy_path do
      # required params
      @param_account_id {:ok, account_id} = Utils.get_param(params, "account_id")
      @param_access_password {:ok, password} = Utils.get_param(params, "access_password")
      @param_repeat_access_password {:ok, re_password} =
                                      Utils.get_param(params, "repeat_access_password")
      @account {:ok, true} = Account.Api.exists(account_id)
      @equals true = password == re_password

      update_params =
        %{
          id: account_id,
          __access_password__: password,
          __action__: :SET_ACCESS_PASSWORD
        }
        |> Utils.remove_nil_fields()

      @account {:ok, _account} = Account.Api.update(update_params)
      {:ok, :access_password_updated}
    else
      {:account, {:error, false}} -> {:error, "account_not_found"}
      {:equals, false} -> {:error, "password_dont_match"}
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    Update transaction password for account
    params:
      - authed
      - permission
      - transaction_password
      - repeat_transaction_password
    rules:
      - password length should be equals 4
  """
  def patch_transaction_password(params) do
    _authed = Access.get(params, "authed")
    _permission = Access.get(params, "permission") || :basic

    happy_path do
      # required params
      @param_account_id {:ok, account_id} = Utils.get_param(params, "account_id")
      @param_transaction_password {:ok, password} =
                                    Utils.get_param(params, "transaction_password")
      @param_repeat_transaction_password {:ok, re_password} =
                                           Utils.get_param(params, "repeat_transaction_password")
      @account {:ok, true} = Account.Api.exists(account_id)
      @length 4 = String.length(password)
      @equals true = password == re_password

      update_params =
        %{
          id: account_id,
          __transaction_password__: password,
          __action__: :SET_TRANSACTION_PASSWORD
        }
        |> Utils.remove_nil_fields()

      @account {:ok, _account} = Account.Api.update(update_params)
      {:ok, :transaction_password_updated}
    else
      {:account, {:error, false}} -> {:error, "account_not_found"}
      {:length, _} -> {:error, "password_length_should_be_four"}
      {:equals, false} -> {:error, "password_dont_match"}
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    Get all accounts

    params:
      - authed
      - permission
  """
  def all(params) do
    _authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic

    Account.Api.all(
      select: Account.bee_permission(permission),
      order: [asc: :first_name, asc: :last_name]
    )
  end

  @doc """
    Get one account

    params:
      - authed
      - permission
      - account_id
  """
  def one(params) do
    _authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic

    happy_path do
      # required params
      @param_account_id {:ok, account_id} = Utils.get_param(params, "account_id")
      @account {:ok, account} = Account.Api.get(account_id)
      {:ok, account}
      |> Utils.visible_fields(permission)
    else
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    Get delete account by id

    params:
      - authed
      - permission
      - account_id
  """
  def delete(params) do
    _authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic

    happy_path do
      # required params
      @param_account_id {:ok, account_id} = Utils.get_param(params, "account_id")
      @account {:ok, account} = Account.Api.get(account_id)
      Account.Api.delete(account)
      |> Utils.visible_fields(permission)
    else
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    Authorize access for account
    params:
      - access_password
      - cpf
  """
  def authorize_access(params) do
    happy_path do
      # required params
      @param_cpf {:ok, cpf} = Utils.get_param(params, "cpf")
      @param_access_password {:ok, password} = Utils.get_param(params, "access_password")
      @account {:ok, account} = Account.Api.get_by(where: [cpf: cpf])
      @password true = Account.Api.check_access_password(account, password)

      {:ok, account}
    else
      {:account, {:error, _}} -> {:error, "account_not_found"}
      {:password, false} -> {:error, "cpf_or_password_invalid"}
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end
end
