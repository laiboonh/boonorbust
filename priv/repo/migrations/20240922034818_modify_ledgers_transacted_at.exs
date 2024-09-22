defmodule Boonorbust.Repo.Migrations.ModifyLedgersTransactedAt do
  use Ecto.Migration

  def up do
    alter table(:ledgers) do
      modify :transacted_at, :date, null: false
      modify :trade_id, :id, null: true
    end
  end

  def down do
    alter table(:ledgers) do
      modify :transacted_at, :date, null: true
      modify :trade_id, :id, null: false
    end
  end
end
