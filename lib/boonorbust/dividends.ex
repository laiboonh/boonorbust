defmodule Boonorbust.Dividends do
  @moduledoc """
  DB Schema
  currency, amount, ex_date, payable_date, local_currency_amount, exchange_rate_used
  """
  alias Boonorbust.Assets.Asset
  alias Boonorbust.Dividends.DividendDeclaration
  alias Boonorbust.Repo

  import Ecto.Query

  @spec all_declarations(Asset.t()) :: [DividendDeclaration.t()]
  def all_declarations(asset) do
    asset_id = asset.id
    Repo.all(DividendDeclaration |> where([dd], dd.asset_id == ^asset_id))
  end

  @spec find_declarations(integer(), Date.t()) :: list(DividendDeclaration)
  def find_declarations(asset_id, ex_date) do
    Repo.all(
      DividendDeclaration
      |> where([dd], dd.asset_id == ^asset_id and dd.ex_date == ^ex_date)
    )
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
      asset.code |> String.starts_with?("NYSE") -> get_dividend_declarations_us(asset)
      asset.code |> String.starts_with?("NASDAQ") -> get_dividend_declarations_us(asset)
      asset.code |> String.starts_with?("SGX") -> get_dividend_declarations_sgx(asset)
    end
  end

  # ThaiBev pay out in SGD
  @spec get_dividend_declarations_sgx(Asset.t()) :: list(map())
  defp get_dividend_declarations_sgx(%{code: "SGX:Y92"} = asset) do
    [_, code] = asset.code |> String.split(":")

    {:ok, %Finch.Response{status: 200, body: body}} =
      Boonorbust.Http.get("https://www.dividends.sg/view/#{code}")

    [_header | content] =
      body
      |> Floki.parse_document!()
      |> Floki.find("tr")

    [_, _, _, _, ex_date, _, _] =
      content |> List.first() |> Floki.find("td") |> Enum.map(&Floki.text(&1))

    if find_declarations(asset.id, Date.from_iso8601!(ex_date |> String.trim())) |> length() > 0 do
      []
    else
      body
      |> Floki.parse_document!()
      |> Floki.find("tr > td > a")
      |> Floki.attribute("href")
      |> Enum.map(fn href -> String.split(href, "=") |> List.last() end)
      |> Enum.map(fn key -> get_div_info_from_sgx(key) end)
      |> Enum.reject(&(&1 == nil))
      |> Enum.map(fn info -> Map.put_new(info, :asset_id, asset.id) end)
    end
  end

  defp get_dividend_declarations_sgx(asset) do
    [_, code] = asset.code |> String.split(":")

    {:ok, %Finch.Response{status: 200, body: body}} =
      Boonorbust.Http.get("https://www.dividends.sg/view/#{code}")

    [_ | content] =
      body |> Floki.parse_document!() |> Floki.find("tr") |> Enum.map(&Floki.find(&1, "td"))

    [_, _, _, _, ex_date, _, _] =
      content |> List.first() |> Floki.find("td") |> Enum.map(&Floki.text(&1))

    if find_declarations(asset.id, Date.from_iso8601!(ex_date |> String.trim())) |> length() > 0 do
      []
    else
      do_get_dividend_declarations_sgx(content, asset.id)
    end
  end

  defp do_get_dividend_declarations_sgx(content, asset_id) do
    content = content |> Enum.map(fn row -> Enum.map(row, &Floki.text(&1)) end)

    content
    |> Enum.reduce([], fn row, acc ->
      [ex_date, payable_date, amount_string] =
        case row do
          [_, _, _, amount_string, ex_date, payable_date, _] ->
            [ex_date, payable_date, amount_string]

          [amount_string, ex_date, payable_date, _] ->
            [ex_date, payable_date, amount_string]
        end

      {currency, amount} = amount_string |> String.trim() |> String.split_at(3)

      if payable_date |> String.trim() == "-" do
        acc
      else
        [
          %{
            currency: currency,
            amount: Decimal.new(amount |> String.trim()),
            ex_date: Date.from_iso8601!(ex_date |> String.trim()),
            payable_date: Date.from_iso8601!(payable_date |> String.trim()),
            asset_id: asset_id
          }
          | acc
        ]
      end
    end)
  end

  @spec get_div_info_from_sgx(String.t()) :: map() | nil
  defp get_div_info_from_sgx(key) do
    {:ok, %Finch.Response{status: 200, body: body}} =
      Boonorbust.Http.get("https://links.sgx.com/1.0.0/corporate-actions/#{key}")

    info =
      body
      |> Floki.parse_document!()
      |> Floki.find(".announcement-group > dl")
      |> Enum.map(&Floki.text(&1))

    ex_date =
      Enum.find(info, fn elem -> String.starts_with?(elem, "Ex-date") end)
      |> String.split(":")
      |> List.last()

    payable_date =
      Enum.find(info, fn elem -> String.starts_with?(elem, "Payment Date") end)

    payable_date =
      payable_date
      |> String.split(":")
      |> List.last()

    rate_or_price_string =
      Enum.find(info, fn elem -> String.starts_with?(elem, "Rate or Price") end)

    if rate_or_price_string == nil do
      nil
    else
      exchange_rate =
        rate_or_price_string
        |> String.split("\n")
        |> Enum.find(&String.starts_with?(&1, "Exchange Rate"))

      if exchange_rate == nil do
        nil
      else
        payment_rate =
          rate_or_price_string
          |> String.split("\n")
          |> Enum.find(&String.starts_with?(&1, "Payment Rate"))

        [currency, amount] =
          payment_rate |> String.split(": ") |> List.last() |> String.split(" ")

        %{
          ex_date: Boonorbust.Utils.convert_to_date(ex_date),
          payable_date: Boonorbust.Utils.convert_to_date(payable_date),
          amount: Decimal.new(amount |> String.trim()),
          currency: String.trim(currency)
        }
      end
    end
  end

  @spec get_dividend_declarations_us(Asset.t()) :: list(map())
  defp get_dividend_declarations_us(asset) do
    [_, code] = asset.code |> String.split(":")

    {:ok, %Finch.Response{status: 200, body: body}} =
      Boonorbust.Http.get(
        "https://financialmodelingprep.com/api/v3/historical-price-full/stock_dividend/#{code}?apikey=#{Application.get_env(:boonorbust, :fmp_api_key)}"
      )

    declarations = Jason.decode!(body)["historical"]

    Enum.reduce(declarations, [], fn d, acc ->
      if d["paymentDate"] == "" do
        acc
      else
        [
          %{
            currency: "USD",
            amount: d["dividend"],
            ex_date: d["date"] |> Date.from_iso8601!(),
            payable_date: d["paymentDate"] |> Date.from_iso8601!(),
            asset_id: asset.id
          }
          | acc
        ]
      end
    end)
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

      if ex_date == "--" || payable_date == "--" do
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
