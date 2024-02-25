defmodule Boonorbust.Repo.Migrations.CreateAssetsTable do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add :name, :citext, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:assets, [:user_id])
    create unique_index(:assets, [:name, :user_id])
  end
end
