defmodule Cumbuca.Core.Account do
  @moduledoc """
    Account Entity
    ---
    User Account to access platform and realize financial operations
  """
  alias Cumbuca.Utils
  use Cumbuca.Schema
  @basic_fields [:id, :first_name, :last_name, :active?, :status, :inserted_at, :updated_at]
  @owner_fields [
    :access_blocked,
    :access_blocked_at,
    :attempts_access,
    :closed?,
    :deactivated_at,
    :initial_balance
  ]
  @account_status [:ACTIVE, :INACTIVE, :ACCESS_BLOCKED, :CLOSED]

  generate_bee do
    permission(:basic, @basic_fields)
    permission(:account_owner, @owner_fields, extends: :basic)
    permission(:admin, [], extends: :account_owner)

    schema "accounts" do
      field :status, Ecto.Enum,
        values: @account_status,
        default: :INACTIVE,
        __swagger__: [description: "status of account", example: "ACTIVE", enum: @account_status]

      field :first_name, :string,
        __swagger__: [description: "first name of account user", example: "Joe"]

      field :last_name, :string,
        __swagger__: [description: "last name of account user", example: "Doe"]

      field :cpf, :string,
        __swagger__: [description: "cpf of account user", example: "123.456.789-11"]

      field :initial_balance, :integer,
        default: 0,
        __swagger__: [description: "initial balance", example: 100_000]

      field :deactivated_at, :utc_datetime,
        __swagger__: [
          description: "DateTime when account was deactivated",
          example: Utils.dateime_to_iso8601()
        ]

      field :access_blocked_at, :utc_datetime,
        __swagger__: [
          description: "DateTime when account access was blocked",
          example: Utils.dateime_to_iso8601()
        ]

      field :closed_at, :utc_datetime,
        __swagger__: [
          description: "DateTime when account access was closed",
          example: Utils.dateime_to_iso8601()
        ]

      field :closed?, :boolean,
        default: false,
        __swagger__: [description: "closed account?", example: true]

      field :active?, :boolean,
        default: false,
        __swagger__: [description: "active account?", example: true]

      field :access_blocked?, :boolean,
        default: false,
        __swagger__: [description: "access blocked by wrong password", example: true]

      field :attempts_access, :integer,
        default: 0,
        __swagger__: [description: "attempts access", example: 3]

      # -- no swagger for this fields
      field :access_password_hash, :string, redact: true, __swagger__: [hidden: true]
      field :transaction_password_hash, :string, redact: true, __swagger__: [hidden: true]
      # --

      # -- virtual fields
      field :__access_password__, :string, virtual: true
      field :__transaction_password__, :string, virtual: true

      field :__action__, Ecto.Enum,
        values: [
          :CREATE,
          :ACTIVATE,
          :DEACTIVATE,
          :BLOCKING_ACCESS,
          :SET_ACCESS_PASSWORD,
          :SET_TRANSACTION_PASSWORD,
          :CLOSE
        ],
        virtual: true

      # --

      timestamps()
    end
  end

  ## change bee default behaviour
  ## Explanations: When call Accounts.Api.insert(params), the changeset_insert is called,
  ## in the same way, when call Accounts.Api.update(params) the changeset_update is called.
  ## So, for changeset actions based, don`t need distinct this for now.
  def changeset_insert(model, attrs), do: changeset(model, attrs)
  def changeset_update(model, attrs), do: changeset(model, attrs)

  ## Changeset for tests purpose
  def changeset_factory(model, attrs), do: changeset_(model, attrs, :insert)

  def changeset(model, attrs),
    do:
      model
      |> run_action(attrs)
      |> put_active()
      |> put_status()

  def run_action(model, %{__action__: :CREATE} = attr), do: create_action(model, attr)
  def run_action(model, %{__action__: :UPDATE} = attr), do: update_action(model, attr)
  def run_action(model, %{__action__: :ACTIVATE} = attr), do: activate_action(model, attr)
  def run_action(model, %{__action__: :DEACTIVATE} = attr), do: deactivate_action(model, attr)
  def run_action(model, %{__action__: :CLOSE} = attr), do: close_action(model, attr)

  def run_action(model, %{__action__: :BLOCKING_ACCESS} = attr),
    do: blocking_access_action(model, attr)

  def run_action(model, %{__action__: :SET_ACCESS_PASSWORD} = attr),
    do: set_access_password_action(model, attr)

  def run_action(model, %{__action__: :SET_TRANSACTION_PASSWORD} = attr),
    do: set_transaction_password_action(model, attr)

  defp create_action(model, attrs) do
    fields = [:first_name, :last_name, :cpf, :initial_balance]

    model
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> unique_constraint(:cpf)
  end

  defp update_action(model, attrs) do
    requireds = [:first_name, :last_name]
    fields = requireds ++ [:attempts_access]

    model
    |> cast(attrs, fields)
    |> validate_required(requireds)
  end

  defp activate_action(model, attrs) do
    model
    |> cast(attrs, [])
    |> validate_required([:access_password_hash])
  end

  defp deactivate_action(model, attrs) do
    model
    |> cast(attrs, [])
    |> put_change(:deactivated_at, Utils.now_sec())
    |> put_change(:active?, true)
  end

  defp blocking_access_action(model, attrs) do
    model
    |> cast(attrs, [])
    |> put_change(:blocked_access_at, Utils.now_sec())
    |> put_change(:blocked_access?, true)
  end

  defp set_access_password_action(model, attrs) do
    model
    |> cast(attrs, [:__access_password__, :access_password_hash])
    |> put_access_password()
  end

  defp set_transaction_password_action(model, attrs) do
    model
    |> cast(attrs, [:__transaction_password__, :transaction_password_hash])
    |> put_transaction_password()
  end

  defp close_action(model, attrs) do
    model
    |> cast(attrs, [])
    |> validate_zeroed_account()
    |> put_change(:closed_at, Utils.now_sec())
    |> put_change(:closed?, true)
  end

  defp validate_zeroed_account(changeset) do
    changeset.data
    |> __MODULE__.Api.get_balance()
    |> case do
      0 -> changeset
      _ -> add_error(changeset, :id, "The account must be zeroed.")
    end
  end

  defp put_access_password(%{changes: %{__access_password__: password}} = changeset) do
    if password && changeset.valid? do
      changeset
      |> validate_length(:__access_password__, length: 8)
      |> put_change(:access_password_hash, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:__access_password__)
    else
      changeset
    end
  end

  defp put_transaction_password(%{changes: %{__transaction_password__: password}} = changeset) do
    if password && changeset.valid? do
      changeset
      |> validate_length(:__transaction_password__, length: 8)
      |> put_change(:transaction_password_hash, Base.encode64(password))
      |> delete_change(:__transaction_password__)
    else
      changeset
    end
  end

  defp put_active(changeset) do
    access_password_hash = get_field(changeset, :access_password_hash)
    transaction_password_hash = get_field(changeset, :transaction_password_hash)
    is_active = get_field(changeset, :active?)

    cond do
      is_active == true -> changeset
      !is_nil(access_password_hash) -> put_change(changeset, :active?, true)
      !is_nil(transaction_password_hash) -> put_change(changeset, :active?, true)
      :else -> changeset
    end
  end

  defp put_status(changeset) do
    is_active = get_field(changeset, :active?)
    is_closed = get_field(changeset, :closed?)
    is_blocked = get_field(changeset, :access_blocked?)

    cond do
      is_closed -> put_change(changeset, :status, :CLOSED)
      is_blocked -> put_change(changeset, :status, :ACCESS_BLOCKED)
      is_active -> put_change(changeset, :status, :ACTIVE)
      is_active == false -> put_change(changeset, :status, :INACTIVE)
      :else -> changeset
    end
  end

  defmodule Api do
    @moduledoc """
      Account Api
    """
    @schema Cumbuca.Core.Account

    # The bee api provides default functions to realize entity crud without Ecto verbosity
    use Bee.Api
    alias Cumbuca.Core.Consolidation

    def check_access_password(%{access_password_hash: nil}, _access_password), do: false

    def check_access_password(%{access_password_hash: hashed_password}, access_password) do
      Bcrypt.verify_pass(access_password, hashed_password)
    end

    def check_transaction_password(%{transaction_password_hash: nil}, _access_password), do: false

    def check_transaction_password(
          %{transaction_password_hash: hashed_password},
          transaction_password
        ) do
      Base.decode64!(hashed_password) == transaction_password
    end

    def get_balance(%{id: id}) do
      {:ok, %{initial_balance: initial_balance}} = get(id)
      from_consolidation = balance_from_consolidation(id)
      initial_balance + from_consolidation
    end

    defp balance_from_consolidation(account_id) do
      from(c in Consolidation,
        where:
          c.account_id == ^account_id and
            c.refunded? == false,
        select:
          coalesce(
            fragment(
              "sum(CASE ? WHEN 'CREDIT' THEN ? WHEN 'DEBIT' THEN -? ELSE 0 END)",
              c.operation,
              c.amount,
              c.amount
            ),
            0
          )
      )
      |> repo().one()
    end

    def has_balance_for_amount(amount, account_id) when is_bitstring(account_id),
      do: has_balance_for_amount(amount, %{id: account_id})

    def has_balance_for_amount(amount, account) do
      balance = get_balance(account)
      amount <= balance
    end

    def reached_max_attempts_access?(account) do
      max_attemps = 3
      account.max_attemps_access > max_attemps
    end
  end
end
