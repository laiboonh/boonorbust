defmodule Boonorbust.Repo.Migrations.AddTransactedAtToLedgers do
  use Ecto.Migration

  def change do
    alter table("ledgers") do
      add :transacted_at, :date
    end
  end
end
