defmodule Boonorbust.Repo.Migrations.AddTypeToAssets do
  use Ecto.Migration

  def change do
    alter table("assets") do
      add :type, :integer, null: false, default: 1
    end

    alter table(:assets) do
      modify :code, :citext, null: false, from: :citext
    end

    drop unique_index(:assets, [:name, :user_id])
    create unique_index(:assets, [:code, :type, :user_id])
  end
end
