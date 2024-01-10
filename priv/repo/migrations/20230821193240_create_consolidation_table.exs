defmodule Chac.Repo.Migrations.CreateConsolidationTable do
  use Ecto.Migration

  def change do
    create table(:consolidations) do
      add :operation, :string, null: false
      add :amount, :integer, default: 0, null: false
      add :description, :string, null: false

      add :refunded?, :boolean, default: false, null: false
      add :refunded_at, :utc_datetime

      add :account_id, references(:accounts, on_delete: :nothing)
      add :paid_to, references(:accounts, on_delete: :nothing)
      add :received_from, references(:accounts, on_delete: :nothing)
      add :transaction_id, references(:transactions, on_delete: :nothing)

      timestamps()
    end
  end
end
