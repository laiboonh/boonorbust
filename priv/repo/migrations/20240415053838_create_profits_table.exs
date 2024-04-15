defmodule Boonorbust.Repo.Migrations.CreateProfitsTable do
  use Ecto.Migration

  def change do
    create table(:profits) do
      add :date, :date, null: false
      add :value, :decimal, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end
end
