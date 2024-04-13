defmodule Boonorbust.Repo.Migrations.AddRootToAssets do
  use Ecto.Migration

  def change do
    alter table("assets") do
      add :root, :boolean, null: false, default: false
    end
  end
end
