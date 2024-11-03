defmodule Boonorbust.Repo.Migrations.CreateUniqueIndexForExchangeRates do
  use Ecto.Migration

  def change do
    create unique_index(:exchange_rates, [:from_currency, :to_currency, :date])
  end
end
