defmodule Boonorbust.Repo.Migrations.CreateLedgersTable do
  use Ecto.Migration

  def change do
    create table(:ledgers) do
      add :trade_id, references(:trades, on_delete: :delete_all), null: false
      add :asset_id, references(:assets, on_delete: :delete_all), null: false
      add :inventory_qty, :decimal, null: false
      add :inventory_cost, :decimal, null: false
      add :weighted_average_cost, :decimal, null: false
      add :unit_cost, :decimal, null: false
      add :total_cost, :decimal, null: false
      add :qty, :decimal, null: false
      add :latest, :boolean, null: false, default: false
    end

    create index(:ledgers, [:asset_id])
  end
end
