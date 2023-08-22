defmodule Cumbuca.Repo.Migrations.CreateTransactionTable do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :amount, :integer, default: 0, null: false
      add :status, :string, default: "inactive", null: false
      add :completed_at, :utc_datetime
      add :processing_at, :utc_datetime
      add :error_at, :utc_datetime
      add :refunded?, :boolean, default: false, null: false
      add :from_refund?, :boolean, default: false, null: false
      add :canceled?, :boolean, default: false, null: false
      add :error?, :boolean, default: false, null: false
      add :reason, :string

      add :payer_id, references(:accounts, on_delete: :nothing)
      add :receiver_id, references(:accounts, on_delete: :nothing)
      add :reference_id, references(:transactions, on_delete: :nothing)

      timestamps()
    end
  end
end
