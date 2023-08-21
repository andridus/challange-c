defmodule Factory.Account do
  @moduledoc """
    Functions to create carts on various scenarios
  """
  alias Cumbuca.AccountContext
  alias Factory.Base, as: B

  @doc """
    Create an account
  """
  def create(map \\ %{}, attrs \\ %{}, opts \\ []) do
    tag = opts[:tag] || :account

    account =
      attrs
      |> Factory.account()

    Map.put(map, tag, account)
  end

  @doc """
    Create account from context
  """
  def create_from_context(map \\ %{}, attrs \\ %{}, opts \\ []) do
    tag = opts[:tag] || :account
    permission = opts[:permission] || :admin

    {:ok, account} =
      attrs
      |> Factory.account(only_map: true)
      |> B.string_key_map()
      |> Map.merge(%{"permission" => permission})
      |> AccountContext.create_account()

    Map.put(map, tag, account)
  end

  @doc """
    Update access password
  """
  def set_access_password(map \\ %{}, password, opts \\ []) do
    account_id = B.get_id(map, :account)

    {:ok, _account} =
      %{
        "account_id" => account_id,
        "permission" => :admin,
        "authed" => nil,
        "access_password" => password,
        "repeat_access_password" => password
      }
      |> AccountContext.patch_access_password()

    map
  end

  @doc """
    Update transaction password
  """
  def set_transaction_password(map \\ %{}, password, opts \\ []) do
    account_id = B.get_id(map, :account)

    {:ok, _account} =
      %{
        "account_id" => account_id,
        "permission" => :admin,
        "authed" => nil,
        "transaction_password" => password,
        "repeat_transaction_password" => password
      }
      |> AccountContext.patch_transaction_password()

    map
  end
end
