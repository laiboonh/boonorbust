defmodule Boonorbust.ExchangeRates do
  import Ecto.Query, warn: false

  alias Boonorbust.ExchangeRates.ExchangeRate
  alias Boonorbust.Repo
  alias Boonorbust.Utils

  @spec convert(binary(), binary(), Date.t(), Decimal.t()) :: %{
          to_amount: Decimal.t(),
          rate_used: Decimal.t()
        }
  def convert(from_currency, to_currency, date, from_amount) do
    rate = get_exchange_rate(from_currency, to_currency, date)
    to_amount = from_amount |> Utils.multiply(rate)
    %{to_amount: to_amount, rate_used: rate}
  end

  @spec get_exchange_rate(String.t(), String.t(), Date.t()) :: Decimal.t()
  def get_exchange_rate(from_currency, to_currency, date) do
    from_currency = from_currency |> String.upcase()
    to_currency = to_currency |> String.upcase()

    if from_currency == to_currency do
      Decimal.new(1)
    else
      exchange_rate =
        case get_exchange_rate_from_db(from_currency, to_currency, date) do
          nil -> get_exchange_rate_from_api(from_currency, to_currency, date)
          exchange_rate -> exchange_rate
        end

      exchange_rate.rate
    end
  end

  @spec get_exchange_rate_from_api(String.t(), String.t(), Date.t()) :: ExchangeRate.t() | nil
  defp get_exchange_rate_from_api(from_currency, to_currency, date) do
    {:ok, %Finch.Response{status: 200, body: body}} =
      Boonorbust.Http.get(
        "https://api.apilayer.com/exchangerates_data/#{date}?symbols=#{to_currency}&base=#{from_currency}",
        [{"apikey", Application.get_env(:boonorbust, :exchange_rate_api_key)}]
      )

    rate = Jason.decode!(body)["rates"][to_currency]

    save_exchange_rate(from_currency, to_currency, date, rate)
  end

  @spec get_exchange_rate_from_db(String.t(), String.t(), Date.t()) :: ExchangeRate.t() | nil
  defp get_exchange_rate_from_db(from_currency, to_currency, date) do
    Repo.one(
      from er in ExchangeRate,
        where:
          er.from_currency == ^from_currency and er.to_currency == ^to_currency and
            er.date == ^date
    )
  end

  @spec save_exchange_rate(String.t(), String.t(), Date.t(), Decimal.t()) :: ExchangeRate.t()
  def save_exchange_rate(from_currency, to_currency, date, rate) do
    ExchangeRate.changeset(%ExchangeRate{}, %{
      from_currency: from_currency,
      to_currency: to_currency,
      date: date,
      rate: rate
    })
    |> Repo.insert!()
  end
end
