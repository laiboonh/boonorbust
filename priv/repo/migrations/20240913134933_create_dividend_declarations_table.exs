defmodule Boonorbust.Repo.Migrations.CreateDividendDeclarationsTable do
  use Ecto.Migration

  def change do
    create table(:dividend_declarations) do
      add :currency, :citext, null: false
      add :amount, :decimal, null: false
      add :ex_date, :date, null: false
      add :payable_date, :date, null: false
      add :asset_id, references(:assets, on_delete: :delete_all), null: false
    end

    create index(:dividend_declarations, [:asset_id])
    create unique_index(:dividend_declarations, [:asset_id, :ex_date, :amount])
  end
end
