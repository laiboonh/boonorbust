defmodule Boonorbust.Repo.Migrations.AlterTradesTable do
  use Ecto.Migration

  def change do
    alter table(:trades) do
      modify :from_asset_id, references(:assets, on_delete: :delete_all),
        null: true,
        from: references(:assets, on_delete: :delete_all)

      modify :to_asset_id, references(:assets, on_delete: :delete_all),
        null: true,
        from: references(:assets, on_delete: :delete_all)

      modify :from_qty, :decimal, null: true
      modify :to_qty, :decimal, null: true
      modify :to_asset_unit_cost, :decimal, null: true
    end
  end
end
