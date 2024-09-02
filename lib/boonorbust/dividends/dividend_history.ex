defmodule Boonorbust.Dividends.DividendHistory do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "dividend_histories" do
    field :currency, :string
    field :amount, :decimal
    field :ex_date, :date
    field :payable_date, :date
    field :local_currency_amount, :decimal

    belongs_to :asset, Boonorbust.Assets.Asset
    belongs_to :exchange_rate_used, Boonorbust.ExchangeRates.ExchangeRate
    timestamps(type: :utc_datetime)
  end

  def changeset(history, attrs) do
    history
    |> cast(attrs, [:currency, :amount, :ex_date, :payable_date, :local_currency_amount])
    |> validate_required([:currency, :amount, :ex_date, :payable_date, :local_currency_amount])
  end
end
