defmodule Boonorbust.ExchangeRates.ExchangeRate do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "exchange_rates" do
    field :from_currency, :string
    field :to_currency, :string
    field :date, :date
    field :rate, :decimal
  end

  def changeset(exchnage_rate, attrs) do
    exchnage_rate
    |> cast(attrs, [:from_currency, :to_currency, :date, :rate])
    |> validate_required([:from_currency, :to_currency, :date, :rate])
  end
end
