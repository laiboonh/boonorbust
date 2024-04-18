defmodule Boonorbust.Repo.Migrations.AddCostToProfits do
  use Ecto.Migration

  def change do
    alter table("profits") do
      add :cost, :decimal, null: false
    end
  end
end
