defmodule Factory do
  @moduledoc """
    This module configure default for all schemas for Factory tests
  """
  alias Cumbuca.Core.Account
  alias Cumbuca.Repo

  # @doc """
  #   create an account with minimum requirement
  # """
  def account(attrs \\ %{}, opts \\ []) do
    %{
      id: Ecto.UUID.generate(),
      first_name: "Joe-" <> Bee.unique(10),
      last_name: "Doe-" <> Bee.unique(10),
      cpf: Brcpfcnpj.cpf_generate(),
      initial_balance: 0
    }
    |> merge_attributes(attrs, Account, opts)
  end

  def merge_attributes(src, attrs, struct_, opts) do
    attributes = Map.merge(src, attrs)

    if opts[:only_map] do
      Map.merge(src, attrs)
    else
      struct(struct_)
      |> struct_.changeset_factory(attributes)
      |> Repo.insert!()
    end
  end
end
