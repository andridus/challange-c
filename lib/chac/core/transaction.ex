defmodule Chac.Core.Transaction do
  @moduledoc """
    Transaction Entity
    ---
    Account Transaction
  """
  alias Chac.Core.{Account, Consolidation}
  alias Chac.Utils
  use Chac.Schema
  @basic_fields [:id, :amount, :status, :completed_at]
  @admin [
    :payer_id,
    :receiver_id,
    :processing_at,
    :error_at,
    :refunded?,
    :from_refund?,
    :error?,
    :error_reason,
    :inserted_at,
    :updated_at
  ]

  @transaction_status [:PENDING, :PROCESSING, :COMPLETED, :CANCELED, :ERROR, :REFUNDED]

  generate_bee do
    permission(:basic, @basic_fields)
    permission(:account_owner, [], extends: :basic)
    permission(:admin, @admin, extends: :account_owner)

    schema "transactions" do
      field :status, Ecto.Enum,
        values: @transaction_status,
        default: :PENDING,
        __swagger__: [
          description: "status of transaction",
          example: "PENDING",
          enum: @transaction_status
        ]

      field :amount, :integer, __swagger__: [description: "amount", example: 10_000]

      field :from_refund?, :boolean,
        __swagger__: [description: "flag to mark if was from refund", example: true]

      field :refunded?, :boolean,
        __swagger__: [description: "flag to mark if was refunded", example: true]

      field :error?, :boolean,
        __swagger__: [description: "flag to mark with error", example: true]

      field :canceled?, :boolean,
        __swagger__: [description: "flag to mark with canceled", example: true]

      field :reason, :string,
        __swagger__: [description: "reason of error", example: "insuficient_funds"]

      field :completed_at, :utc_datetime,
        __swagger__: [
          description: "DateTime when the transaction was completed",
          example: Utils.dateime_to_iso8601()
        ]

      field :processing_at, :utc_datetime,
        __swagger__: [
          description: "DateTime when the processing transaction was started",
          example: Utils.dateime_to_iso8601()
        ]

      field :error_at, :utc_datetime,
        __swagger__: [
          description: "DateTime when the error occurs",
          example: Utils.dateime_to_iso8601()
        ]

      # -- virtual fields
      field :__action__, Ecto.Enum,
        values: [
          :CREATE,
          :CREATE_REFUNDED,
          :PROCESS,
          :COMPLETE,
          :REFUND,
          :CANCEL,
          :ERROR
        ],
        virtual: true

      # --

      timestamps()

      belongs_to :payer, Account, foreign_key: :payer_id
      belongs_to :receiver, Account, foreign_key: :receiver_id
      belongs_to :reference, __MODULE__, foreign_key: :reference_id
      has_many :consolidations, Consolidation
    end
  end

  ## change bee default behaviour
  ## Explanations: same of  Account
  def changeset_insert(model, attrs), do: changeset(model, attrs)
  def changeset_update(model, attrs), do: changeset(model, attrs)

  ## Changeset for tests purpose
  def changeset_factory(model, attrs), do: changeset_(model, attrs, :insert)

  def changeset(model, attrs), do: run_action(model, attrs)

  def run_action(model, %{__action__: :CREATE} = attr), do: create_action(model, attr)

  def run_action(model, %{__action__: :CREATE_REFUNDED} = attr),
    do: create_refunded_action(model, attr)

  def run_action(model, %{__action__: :PROCESS} = attr), do: process_action(model, attr)
  def run_action(model, %{__action__: :COMPLETE} = attr), do: complete_action(model, attr)
  def run_action(model, %{__action__: :REFUND} = attr), do: refund_action(model, attr)
  def run_action(model, %{__action__: :ERROR} = attr), do: error_action(model, attr)
  def run_action(model, %{__action__: :CANCEL} = attr), do: cancel_action(model, attr)

  defp create_action(model, attrs) do
    fields = [:payer_id, :receiver_id, :amount]

    model
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> has_sufficient_balance()
    |> put_change(:status, :PENDING)
  end

  defp create_refunded_action(model, attrs) do
    fields = [:payer_id, :receiver_id, :amount, :reference_id]

    model
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> foreign_key_constraint(:reference_id)
    |> put_change(:status, :PENDING)
    |> put_change(:from_refund?, true)
  end

  defp process_action(model, attrs) do
    model
    |> cast(attrs, [])
    |> put_change(:processing_at, Utils.now_sec())
    |> put_change(:status, :PROCESSING)
  end

  defp complete_action(model, attrs) do
    model
    |> cast(attrs, [])
    |> put_change(:completed_at, Utils.now_sec())
    |> put_change(:status, :COMPLETED)
  end

  defp refund_action(model, attrs) do
    fields = [:payer_id, :receiver_id, :amount, :refunded?]

    model
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> put_change(:status, :REFUNDED)
    |> put_change(:refunded?, true)
  end

  defp cancel_action(model, attrs) do
    fields = [:status, :canceled?]

    model
    |> cast(attrs, fields)
    |> put_canceled()
  end

  defp error_action(model, attrs) do
    fields = [:reason]

    model
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> put_change(:error_at, Utils.now_sec())
    |> put_change(:error?, true)
    |> put_change(:status, :ERROR)
  end

  defp has_sufficient_balance(changeset) do
    amount = get_field(changeset, :amount)
    payer_id = get_field(changeset, :payer_id)
    has_balance = Account.Api.has_balance_for_amount(amount, payer_id)

    if has_balance do
      changeset
    else
      add_error(changeset, :amount, "insuficient_funds")
    end
  end

  defp put_canceled(changeset) do
    status = get_field(changeset, :status)

    cond do
      status == :PENDING ->
        changeset
        |> put_change(:canceled?, true)
        |> put_change(:status, :CANCELED)

      :else ->
        changeset
        |> add_error(:status, "only cancel when PENDING status")
    end
  end

  defmodule Api do
    @moduledoc """
      Transaction Api
    """
    @schema Chac.Core.Transaction

    # The bee api provides default functions to realize entity crud without Ecto verbosity
    use Bee.Api
  end
end
