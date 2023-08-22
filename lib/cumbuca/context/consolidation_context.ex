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
      @transaction {:ok, %{status: :PENDING} = transaction} =
                     Transaction.Api.get(transaction_id, preload: [:consolidations])
      consolidate_processing(transaction)
    else
      {:param_transaction_id, {:error, _error}} -> {:error, "param_transaction_id_not_found"}
      {:transaction, {:ok, _}} -> {:error, "invalid_transaction"}
      {:transaction, {:error, msg}} -> {:error, msg}
    end
  end

  defp consolidate_processing(transaction) do
    happy_path do
      @active_payer_account {:ok, %{active?: true}} = Account.Api.get(transaction.payer_id)
      update_params = %{id: transaction.id, __action__: :PROCESS}
      @transaction {:ok, _updated} = Transaction.Api.update(update_params)
      @to_complete {:ok, _} = Repo.transaction(fn -> create_debit_and_credit(transaction) end)
      refund_consolidations(transaction)
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

  defp refund_consolidations(%{from_refund?: false}), do: :nothing

  defp refund_consolidations(%{from_refund?: true} = transaction) do
    Consolidation.Api.all(where: [transaction_id: transaction.reference_id])
    |> Enum.map(fn x ->
      Consolidation.Api.update(%{id: x.id, __action__: :REFUND})
    end)
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
        description: "PIX ENVIADO",
        __action__: :DEBIT
      }

      @debit {:ok, _consolidation} = Consolidation.Api.insert(debit_params)

      ## Consolidate CREDIT
      credit_params = %{
        account_id: transaction.receiver_id,
        transaction_id: transaction.id,
        received_from: transaction.payer_id,
        description: "PIX RECEBIDO",
        amount: transaction.amount,
        __action__: :CREDIT
      }

      @credit {:ok, _consolidation} = Consolidation.Api.insert(credit_params)

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
      - authed
      - permissions
      - account_id
      - from
      - to
  """
  def all_by_account(params) do
    authed = Access.get(params, "authed")
    permission = Access.get(params, "permission") || :basic
    before30 = Date.utc_today() |> Date.add(-30)
    now = Date.utc_today()
    from = Access.get(params, "from") |> Utils.parse_to_date() || before30
    to = Access.get(params, "to") |> Utils.parse_to_date() || now

    happy_path do
      # required params
      @param_account_id {:ok, account_id} = Utils.get_param(params, "account_id")

      # validate if account is authed user
      @granted_authed true = authed.id == account_id

      Consolidation.Api.all_by_account_and_date(account_id, from, to)
      |> Enum.map(&Utils.visible_fields(&1, permission))
    else
      {:granted_authed, false} -> {:error, "operation_not_allowed_for_this_user"}
      {atom, {:error, error}} -> {:error, "#{atom}_#{error}"}
    end
  end
end
