defmodule Boonorbust.Dividends do
  @moduledoc """
  DB Schema
  currency, amount, ex_date, payable_date, local_currency_amount, exchange_rate_used
  """
  alias Boonorbust.Assets.Asset
  alias Boonorbust.Dividends.DividendDeclaration
  alias Boonorbust.Repo

  import Ecto.Query

  @spec all(Asset.t()) :: [DividendDeclaration.t()]
  def all(asset) do
    asset_id = asset.id
    Repo.all(DividendDeclaration |> where([dd], dd.asset_id == ^asset_id))
  end

  @spec upsert_dividend_declarations(Asset.t()) :: {any(), nil | list()}
  def upsert_dividend_declarations(asset) do
    Repo.insert_all(
      DividendDeclaration,
      get_dividend_declarations(asset),
      on_conflict: :nothing
    )
  end

  defp get_dividend_declarations(%Asset{type: :stock} = asset) do
    cond do
      asset.code |> String.starts_with?("HKEX") -> get_dividend_declarations_hkex(asset)
      asset.code |> String.starts_with?("NYSE") -> get_dividend_declarations_hkex(asset)
      asset.code |> String.starts_with?("NASDAQ") -> get_dividend_declarations_hkex(asset)
      asset.code |> String.starts_with?("SGX") -> get_dividend_declarations_hkex(asset)
    end
  end

  @spec get_dividend_declarations_hkex(Asset.t()) :: list(map())
  defp get_dividend_declarations_hkex(asset) do
    [_, code] = asset.code |> String.split(":")

    {:ok, %Finch.Response{status: 200, body: body}} =
      Boonorbust.Http.get(
        "https://www.etnet.com.hk/www/eng/stocks/realtime/quote_dividend.php?code=#{code}"
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

        [
          %{
            currency: currency,
            amount: amount,
            ex_date: ex_date,
            payable_date: payable_date,
            asset_id: asset.id
          }
          | acc
        ]
      end
    end)
  end

  @spec convert_date_string(binary()) :: Date.t()
  defp convert_date_string(input) do
    [day, month, year] = input |> String.split("/")
    {year, ""} = year |> Integer.parse()
    {month, ""} = month |> Integer.parse()
    {day, ""} = day |> Integer.parse()
    Date.from_erl!({year, month, day})
  end

  @spec convert_details_string(binary()) :: {String.t(), float()}
  defp convert_details_string(input) do
    [_, _, currency, amount | _tail] = input |> String.replace(",", "") |> String.split(" ")
    {amount, ""} = amount |> Float.parse()
    {currency, amount}
  end
end
