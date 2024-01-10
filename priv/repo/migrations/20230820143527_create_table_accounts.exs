defmodule Chac.Repo.Migrations.CreateTableAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :status, :string, default: "inactive", null: false
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :cpf, :string, null: false
      add :initial_balance, :integer, default: 0, null: false
      add :deactivated_at, :utc_datetime
      add :access_blocked_at, :utc_datetime
      add :closed_at, :utc_datetime
      add :closed?, :boolean, default: false, null: false
      add :active?, :boolean, default: false, null: false
      add :access_blocked?, :boolean, default: false, null: false
      add :attempts_access, :integer, default: 0, null: false
      add :access_password_hash, :string
      add :transaction_password_hash, :string
      timestamps()
    end

    create unique_index(:accounts, :cpf)
  end
end
