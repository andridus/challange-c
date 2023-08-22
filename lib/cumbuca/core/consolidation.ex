defmodule Cumbuca.Core.Consolidation do
  @moduledoc """
    Consolidated Transaction Entity
    ---
    This entity is the operational bank statements
  """
  alias Cumbuca.Core.{Account, Transaction}
  alias Cumbuca.Utils
  use Cumbuca.Schema

  @basic_fields [
    :id,
    :amount,
    :operation,
    :description,
    :received_from,
    :paid_to,
    :refunded_at,
    :refunded?,
    :inserted_at,
    :updated_at
  ]
  @admin []

  @operations [:DEBIT, :CREDIT]

  generate_bee do
    permission(:basic, @basic_fields)
    permission(:account_owner, [], extends: :basic)
    permission(:admin, @admin, extends: :account_owner)

    schema "consolidations" do
      field :operation, Ecto.Enum,
        values: @operations,
        __swagger__: [
          description: "operation of this transaction",
          example: "DEBIT",
          enum: @operations
        ]

      field :amount, :integer, __swagger__: [description: "amount", example: 10_000]

      field :description, :string,
        __swagger__: [description: "transaction description", example: "OPERAÇÃO DE DEBITO"]

      field :refunded?, :boolean,
        __swagger__: [description: "flag to mark if was refunded", example: true]

      field :refunded_at, :utc_datetime,
        __swagger__: [
          description: "DateTime when the transaction was refunded",
          example: Utils.dateime_to_iso8601()
        ]

      # -- virtual fields
      field :__action__, Ecto.Enum,
        values: [
          :DEBIT,
          :CREDIT,
          :REFUND
        ],
        virtual: true

      # --

      timestamps()

      belongs_to :account, Account
      belongs_to :paid, Account, foreign_key: :paid_to
      belongs_to :received, Account, foreign_key: :received_from
      belongs_to :transaction, Transaction
    end
  end

  ## change bee default behaviour
  ## Explanations: same of  Account
  def changeset_insert(model, attrs), do: changeset(model, attrs)
  def changeset_update(model, attrs), do: changeset(model, attrs)

  ## Changeset for tests purpose
  def changeset_factory(model, attrs), do: changeset_(model, attrs, :insert)

  def changeset(model, attrs), do: run_action(model, attrs)

  def run_action(model, %{__action__: :DEBIT} = attr), do: debit_action(model, attr)
  def run_action(model, %{__action__: :CREDIT} = attr), do: credit_action(model, attr)
  def run_action(model, %{__action__: :REFUND} = attr), do: refund_action(model, attr)

  defp debit_action(model, attrs) do
    fields = [:paid_to, :amount, :account_id, :description, :transaction_id]

    model
    |> cast(attrs, fields)
    |> has_sufficient_balance()
    |> put_change(:operation, :DEBIT)
  end

  defp credit_action(model, attrs) do
    fields = [:received_from, :amount, :account_id, :description, :transaction_id]

    model
    |> cast(attrs, fields)
    |> put_change(:operation, :CREDIT)
  end

  defp refund_action(model, attrs) do
    fields = []

    model
    |> cast(attrs, fields)
    |> put_change(:refunded?, true)
    |> put_change(:refunded_at, Utils.now_sec())
  end

  defp has_sufficient_balance(changeset) do
    amount = get_field(changeset, :amount)
    payer_id = get_field(changeset, :account_id)
    has_balance = Account.Api.has_balance_for_amount(amount, payer_id)

    if has_balance do
      changeset
    else
      add_error(changeset, :amount, "insuficient_funds")
    end
  end

  defmodule Api do
    @moduledoc """
      Transaction Api
    """
    @schema Cumbuca.Core.Consolidation

    # The bee api provides default functions to realize entity crud without Ecto verbosity
    use Bee.Api

    def all_by_account_and_date(account_id, from, to) do
      from(
        s in schema(),
        where:
          s.account_id == ^account_id and
            fragment("?::date", s.inserted_at) >= ^from and
            fragment("?::date", s.inserted_at) <= ^to
      )
      |> repo().all()
    end
  end
end
