defmodule Boonorbust.Repo.Migrations.CreateTagsTable do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :citext, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:tags, [:user_id])
    create unique_index(:tags, [:name, :user_id])
  end
end
