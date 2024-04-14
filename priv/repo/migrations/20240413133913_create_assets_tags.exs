defmodule Boonorbust.Repo.Migrations.CreateAssetsTags do
  use Ecto.Migration

  def change do
    create table(:assets_tags) do
      add :tag_id, references(:tags)
      add :asset_id, references(:assets)
    end

    create unique_index(:assets_tags, [:tag_id, :asset_id])
  end
end
