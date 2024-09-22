defmodule Boonorbust.Repo.Migrations.AddUserIdToLedgers do
  use Ecto.Migration

  def change do
    alter table(:ledgers) do
      add :user_id, references(:users, on_delete: :delete_all)
    end
  end
end
