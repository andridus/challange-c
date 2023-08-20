defmodule Cumbuca.AccountsContext do
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

      insert_params =
        %{
          id: account_id,
          first_name: first_name,
          last_name: last_name,
          __action__: :UPDATE
        }
        |> Utils.remove_nil_fields()

      Account.Api.update(insert_params)
      |> Utils.visible_fields(permission)
    else
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {:account, {:error, false}} -> {:error, "account_not_found"}
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
end
