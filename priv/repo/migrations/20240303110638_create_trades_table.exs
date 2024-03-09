defmodule Boonorbust.Repo.Migrations.CreateTradesTable do
  use Ecto.Migration

  def change do
    create table(:trades) do
      add :from_asset_id, references(:assets, on_delete: :delete_all), null: false
      add :to_asset_id, references(:assets, on_delete: :delete_all), null: false
      add :from_qty, :decimal, null: false
      add :to_qty, :decimal, null: false
      add :to_asset_unit_cost, :decimal, null: false
      add :transacted_at, :date, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:trades, [:user_id])
  end
end
