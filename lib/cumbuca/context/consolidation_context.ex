defmodule Cumbuca.ConsolidationContext do
  @moduledoc """
    Context of transaction functions
  """
  alias Cumbuca.Core.{Account, Consolidation, Transaction}
  alias Cumbuca.Repo
  alias Cumbuca.Utils

  import Happy

  @doc """
    Process transaction  to consolidation
    params:
      - transaction_id
  """
  def consolidate_transaction(params) do
    happy_path do
      # required params
      @param_transaction_id {:ok, transaction_id} = Utils.get_param(params, "transaction_id")
      @transaction {:ok, %{status: :PENDING} = transaction} = Transaction.Api.get(transaction_id)
      consolidate_processing(transaction)
    else
      {:param_transaction_id, {:error, error}} -> {:error, :param}
      {:transaction, {:error, _}} -> {:error, "#"}
    end
  end

  defp consolidate_processing(transaction) do
    happy_path do
      @active_payer_account {:ok, %{active?: true}} = Account.Api.get(transaction.payer_id)

      update_params = %{id: transaction.id, __action__: :PROCESS}
      @transaction {:ok, update} = Transaction.Api.update(update_params)
      @to_complete {:ok, _} = Repo.transaction(fn -> create_debit_and_credit(transaction) end)

      :ok
    else
      {:active_payer_account, _} ->
        processing_to_error(transaction, "payer_account_not_available")

      {:granted_payer, false} ->
        processing_to_error(transaction, "operation_not_allowed_for_this_user")

      {:to_complete, {:error, msg}} ->
        processing_to_error(transaction, msg)

      _ ->
        processing_to_error(transaction, "generic_error")
    end
  end

  defp create_debit_and_credit(transaction) do
    happy_path do
      ## complete transaction
      update_params = %{id: transaction.id, __action__: :COMPLETE}
      @transaction {:ok, transaction} = Transaction.Api.update(update_params)

      ## Consolidate DEBIT
      debit_params = %{
        account_id: transaction.payer_id,
        transaction_id: transaction.id,
        paid_to: transaction.receiver_id,
        amount: transaction.amount,
        description: "TRANSFERENCIA INTERNA",
        __action__: :DEBIT
      }

      @debit {:ok, consolidation} = Consolidation.Api.insert(debit_params)

      ## Consolidate CREDIT
      credit_params = %{
        account_id: transaction.receiver_id,
        transaction_id: transaction.id,
        received_from: transaction.payer_id,
        description: "TRANSFERENCIA INTERNA",
        amount: transaction.amount,
        __action__: :CREDIT
      }

      @credit {:ok, consolidation} = Consolidation.Api.insert(credit_params)

      transaction
    else
      {:credit, {:error, changeset}} ->
        Utils.parse_changeset_string(changeset, "receiver")
        |> Repo.rollback()

      {:debit, {:error, changeset}} ->
        Utils.parse_changeset_string(changeset, "payer")
        |> Repo.rollback()

      _ ->
        Repo.rollback("generic_error")
    end
  end

  defp processing_to_error(transaction, reason) do
    update_params = %{id: transaction.id, reason: reason, __action__: :ERROR}
    Transaction.Api.update(update_params)
  end

  @doc """
    Get all consolidations by account and date
    params:
      - account_id
      - from
      - to
  """
  def all_by_account(params) do
    before30 = Date.utc_today() |> Date.add(-30)
    now = Date.utc_today()
    from = Access.get(params, "from") |> Utils.parse_to_date() || before30
    to = Access.get(params, "to") |> Utils.parse_to_date() || now

    happy_path do
      # required params
      @param_account_id {:ok, account_id} = Utils.get_param(params, "account_id")
      Consolidation.Api.all_by_account_and_date(account_id, from, to)
    else
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
    end
  end
end
