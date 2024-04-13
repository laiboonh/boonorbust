defmodule Boonorbust.Repo.Migrations.AddNoteToTrades do
  use Ecto.Migration

  def change do
    alter table("trades") do
      add :note, :string
    end
  end
end
