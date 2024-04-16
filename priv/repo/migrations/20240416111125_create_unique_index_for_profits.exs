defmodule Boonorbust.Repo.Migrations.CreateUniqueIndexForProfits do
  use Ecto.Migration

  def change do
    create index(:profits, [:user_id])
    create unique_index(:profits, [:date, :user_id])
  end
end
