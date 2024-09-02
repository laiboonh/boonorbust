defmodule Boonorbust.Repo.Migrations.CreateDividendHistoriesTable do
  use Ecto.Migration

  def change do
    create table(:dividend_histories) do
      add :currency, :citext, null: false
      add :amount, :decimal, null: false
      add :ex_date, :date, null: false
      add :payable_date, :date, null: false
      add :local_currency_amount, :decimal, null: false
      add :exchange_rate_used, :decimal, null: false
      add :asset_id, references(:assets, on_delete: :delete_all), null: false
    end

    create index(:dividend_histories, [:asset_id])
  end
end
