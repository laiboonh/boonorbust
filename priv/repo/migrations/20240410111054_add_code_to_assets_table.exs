defmodule Boonorbust.Repo.Migrations.AddCodeToAssetsTable do
  use Ecto.Migration

  def change do
    alter table("assets") do
      add :code, :citext
    end
  end
end
