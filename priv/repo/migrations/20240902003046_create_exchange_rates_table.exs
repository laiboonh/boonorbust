defmodule Boonorbust.Repo.Migrations.CreateExchangeRatesTable do
  use Ecto.Migration

  def change do
    create table(:exchange_rates) do
      add :from_currency, :citext, null: false
      add :to_currency, :citext, null: false
      add :date, :date, null: false
      add :rate, :decimal, null: false
    end
  end
end
