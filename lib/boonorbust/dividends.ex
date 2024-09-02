defmodule Boonorbust.Dividends do
  @moduledoc """
  DB Schema
  currency, amount, ex_date, payable_date, local_currency_amount, exchange_rate_used
  """

  def get_dividend_history_hkex(asset_code) do
    {:ok, %Finch.Response{status: 200, body: body}} =
      Boonorbust.Http.get(
        "https://www.etnet.com.hk/www/eng/stocks/realtime/quote_dividend.php?code=#{asset_code}"
      )

    [_header | contents] =
      body
      |> Floki.parse_document!()
      |> Floki.find("div.DivFigureContent > div > table")
      |> Floki.find("tr")

    contents
    |> Enum.reduce([], fn content, acc ->
      [_, _, details, ex_date, _, _, payable_date] =
        Floki.find(content, "tr") |> Floki.find("td") |> Enum.map(&Floki.text(&1))

      [details, ex_date, payable_date]

      if ex_date == "--" do
        acc
      else
        ex_date = convert_date_string(ex_date)
        payable_date = convert_date_string(payable_date)
        {currency, amount} = convert_details_string(details)
        [[currency, amount, ex_date, payable_date] | acc]
      end
    end)
  end

  @spec convert_date_string(binary()) :: Date.t()
  def convert_date_string(input) do
    [day, month, year] = input |> String.split("/")
    {year, ""} = year |> Integer.parse()
    {month, ""} = month |> Integer.parse()
    {day, ""} = day |> Integer.parse()
    Date.from_erl!({year, month, day})
  end

  @spec convert_details_string(binary()) :: {String.t(), float()}
  def convert_details_string(input) do
    [_, _, currency, amount] = input |> String.split(" ")
    {amount, ""} = amount |> Float.parse()
    {currency, amount}
  end
end
