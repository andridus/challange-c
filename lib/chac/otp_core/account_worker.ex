defmodule Chac.OTPCore.AccountWorker do
  @moduledoc """
    Account Transactions Queue for processing
  """
  @timeout 5000
  alias Chac.ConsolidationContext
  use GenServer
  require Logger
  ### GenServer API
  def init(id) do
    Process.send_after(self(), :processing, @timeout)
    Logger.warn("[ACCOUNT #{id}]:START WORKER, timeout=#{@timeout}ms")
    {:ok, {id, []}}
  end

  def handle_info(:processing, {id, queue}) do
    transaction_id = List.last(queue)

    if is_nil(transaction_id) do
      Logger.warn("[ACCOUNT #{id}]: EMPTY TRANSACTIONS")
      Process.send_after(self(), :processing, @timeout)
      {:noreply, {id, queue}}
    else
      Logger.info("[ACCOUNT #{id}]:PROCESS #{transaction_id}")

      ConsolidationContext.consolidate_transaction(%{"transaction_id" => transaction_id})
      |> case do
        {:ok, %{reason: reason}} ->
          Logger.error("[ACCOUNT #{id}]: ERROR #{transaction_id} | #{reason}")

        _ ->
          :ok
      end

      send(self(), {:drop, transaction_id})
      {:noreply, {id, queue}}
    end
  end

  def handle_info({:drop, transaction_id}, {id, queue0}) do
    Logger.info("[ACCOUNT #{id}]:DROP #{transaction_id}")
    queue1 = Enum.filter(queue0, &(&1 != transaction_id))
    Process.send_after(self(), :processing, @timeout)
    {:noreply, {id, queue1}}
  end

  def handle_cast(:process, state) do
    Process.send_after(self(), :processing, @timeout)
    {:noreply, state}
  end

  def handle_cast({:add, transaction_id}, {id, queue}) do
    {:noreply, {id, [transaction_id | queue]}}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  ### Client API / Helper functions

  def start_link(opts \\ []) do
    id = opts[:id]

    if is_nil(id) do
      Logger.error("DONT START WORKER: account id not defined!")
    else
      name = id |> Base.encode64()
      GenServer.start_link(__MODULE__, id, name: :"account_#{name}")
    end
  end

  def add(account, transaction_id) do
    name = account |> Base.encode64()
    GenServer.cast(:"account_#{name}", {:add, transaction_id})
  end
end
