defmodule Chac.TransactionContext do
  @moduledoc """
    Context of transaction functions
  """
  alias Chac.Core.{Account, Transaction}
  alias Chac.OTPCore.AccountWorker
  alias Chac.{Repo, Utils}
  import Happy

  @doc """
    Register a transaction (auth required)
    params:
      - authed
      - permission
      - payer_id
      - receiver_id
      - amount
  """
  def create_transaction(params) do
    authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic

    happy_path do
      # required params
      @param_payer_id {:ok, payer_id} = Utils.get_param(params, "payer_id")
      @param_receiver_id {:ok, receiver_id} = Utils.get_param(params, "receiver_id")
      @param_amount {:ok, amount} = Utils.get_param(params, "amount")
      @param_transaction_password {:ok, transaction_password} =
                                    Utils.get_param(params, "transaction_password")

      @active_payer_account {:ok, %{active?: true} = payer} = Account.Api.get(payer_id)
      @active_receiver_account {:ok, %{active?: true}} = Account.Api.get(receiver_id)

      # validate if payer is authed user
      @granted_payer true = authed.id == payer_id
      # validate if transaction password of payer
      @password true = Account.Api.check_transaction_password(payer, transaction_password)

      insert_params = %{
        payer_id: payer_id,
        receiver_id: receiver_id,
        amount: amount,
        __action__: :CREATE
      }

      {:ok, transaction} =
        Transaction.Api.insert(insert_params)
        |> Utils.visible_fields(permission)

      AccountWorker.add(payer_id, transaction.id)

      {:ok, transaction}
    else
      {:active_payer_account, {:error, :not_found}} -> {:error, "payer_account_not_found"}
      {:active_payer_account, _} -> {:error, "payer_account_not_available"}
      {:active_receiver_account, {:error, :not_found}} -> {:error, "receiver_account_not_found"}
      {:active_receiver_account, _} -> {:error, "receiver_account_not_available"}
      {:granted_payer, false} -> {:error, "operation_not_allowed_for_this_user"}
      {:password, false} -> {:error, "invalid_password"}
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    get transaction by id(auth required)
    params:
      - authed
      - permission
      - transaction_id
  """
  def by_id(params) do
    authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :admin

    happy_path do
      # required params
      @param_transaction_id {:ok, transaction_id} = Utils.get_param(params, "transaction_id")
      @transaction {:ok, transaction} = Transaction.Api.get(transaction_id)

      # validate if payer is authed user
      @granted_payer true = authed.id == transaction.payer_id

      {:ok, transaction}
      |> Utils.visible_fields(permission)
    else
      {:active_payer_account, {:error, :not_found}} -> {:error, "payer_account_not_found"}
      {:active_payer_account, _} -> {:error, "payer_account_not_available"}
      {:granted_payer, false} -> {:error, "operation_not_allowed_for_this_user"}
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    Cancel a transaction (auth required)
    params:
      - authed
      - permission
      - transaction_id
  """
  def cancel_transaction(params) do
    authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic

    happy_path do
      # required params
      @param_transaction_id {:ok, transaction_id} = Utils.get_param(params, "transaction_id")
      @transaction {:ok, %{payer_id: payer_id}} = Transaction.Api.get(transaction_id)

      @active_payer_account {:ok, %{active?: true}} = Account.Api.get(payer_id)

      # validate if payer is authed user
      @granted_payer true = authed.id == payer_id

      update_params = %{id: transaction_id, __action__: :CANCEL}

      Transaction.Api.update(update_params)
      |> Utils.visible_fields(permission)
    else
      {:active_payer_account, {:error, :not_found}} -> {:error, "payer_account_not_found"}
      {:active_payer_account, _} -> {:error, "payer_account_not_available"}
      {:granted_payer, false} -> {:error, "operation_not_allowed_for_this_user"}
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  @doc """
    Refund a transaction (auth required)
    params:
      - authed
      - permission
      - transaction_id
  """
  def refund_transaction(params) do
    authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic

    happy_path do
      # required params
      @param_transaction_id {:ok, transaction_id} = Utils.get_param(params, "transaction_id")
      @transaction {:ok,
                    %{payer_id: payer_id, refunded?: false, status: :COMPLETED} = transaction} =
                     Transaction.Api.get(transaction_id)

      @active_payer_account {:ok, %{active?: true}} = Account.Api.get(payer_id)

      # validate if payer is authed user
      @granted_payer true = authed.id == payer_id

      @refunded_transaction {:ok, transaction} =
                              Repo.transaction(fn -> refund_transaction_priv(transaction) end)

      AccountWorker.add(payer_id, transaction.id)

      {:ok, transaction}
      |> Utils.visible_fields(permission)
    else
      {:active_payer_account, {:error, :not_found}} -> {:error, "payer_account_not_found"}
      {:active_payer_account, _} -> {:error, "payer_account_not_available"}
      {:granted_payer, false} -> {:error, "operation_not_allowed_for_this_user"}
      {:transaction, {:ok, %{refunded?: true}}} -> {:error, "already_refunded"}
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end

  defp refund_transaction_priv(transaction) do
    happy_path do
      refund_params = %{id: transaction.id, __action__: :REFUND}

      @transaction_refunded {:ok, _} = Transaction.Api.update(refund_params)

      insert_params = %{
        payer_id: transaction.receiver_id,
        receiver_id: transaction.payer_id,
        amount: transaction.amount,
        reference_id: transaction.id,
        __action__: :CREATE_REFUNDED
      }

      @transaction {:ok, refunded} = Transaction.Api.insert(insert_params)

      refunded
    else
      {atom, :error} -> {:error, "#{atom}_not_found"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
      {_atom, error} -> {:error, error}
    end
  end
end
