defmodule Chac.Worker.AccountsSupervisor do
  @moduledoc """
    Supervisor for accounts
  """
  use DynamicSupervisor

  alias Chac.Core.Account
  alias Chac.OTPCore.AccountWorker

  def start_link do
    result = DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

    ## start all accounts queue for transactions
    Account.Api.all(where: [closed?: false])
    |> Enum.each(&start_account(&1.id))

    result
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_account(id) do
    spec = {AccountWorker, id: id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
