defmodule Boonorbust.ExchangeRates do
  @spec get_exchange_rate(String.t(), String.t(), Date.t()) :: float()
  def get_exchange_rate(from_currency, to_currency, date) do
    {:ok, %Finch.Response{status: 200, body: body}} =
      Boonorbust.Http.get(
        "https://api.apilayer.com/exchangerates_data/#{date}?symbols=#{to_currency}&base=#{from_currency}",
        [{"apikey", Application.get_env(:boonorbust, :exchange_rate_api_key)}]
      )

    Jason.decode!(body)["rates"][to_currency]
  end
end
