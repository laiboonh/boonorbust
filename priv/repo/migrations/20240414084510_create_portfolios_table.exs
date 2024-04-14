defmodule Boonorbust.Repo.Migrations.CreatePortfoliosTable do
  use Ecto.Migration

  def change do
    create table(:portfolios) do
      add :name, :citext, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:portfolios, [:user_id])
    create unique_index(:portfolios, [:name, :user_id])

    create table(:portfolios_tags) do
      add :tag_id, references(:tags)
      add :portfolio_id, references(:portfolios)
    end

    create unique_index(:portfolios_tags, [:tag_id, :portfolio_id])
  end
end
