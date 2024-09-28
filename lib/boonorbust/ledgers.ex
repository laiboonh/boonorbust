defmodule Boonorbust.Ledgers do
  import Ecto.Query, warn: false

  alias Boonorbust.Assets
  alias Boonorbust.Assets.Asset
  alias Boonorbust.Ledgers.Ledger
  alias Boonorbust.Portfolios
  alias Boonorbust.Portfolios.Portfolio
  alias Boonorbust.Profits
  alias Boonorbust.Repo
  alias Boonorbust.Trades
  alias Boonorbust.Trades.Trade
  alias Boonorbust.Utils
  alias Ecto.Multi

  @spec create(%{atom => any()}) :: {:ok, Ledger.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Ledger{}
    |> Ledger.changeset(attrs)
    |> Repo.insert()
  end

  @spec recalculate(integer()) :: :ok
  def recalculate(user_id) do
    {_, _} = delete(user_id)

    Trades.all_asc_trasacted_at(user_id)
    |> Enum.each(&record(&1))
  end

  @spec record(Trade.t()) :: {:ok, any()} | {:error, any()} | Ecto.Multi.failure()
  def record(trade) do
    sell(trade)
    |> Multi.merge(fn changes ->
      sell_asset_latest_ledger = Map.get(changes, :insert_sell_asset_latest_ledger)
      buy(trade, sell_asset_latest_ledger)
    end)
    |> Repo.transaction()
  end

  @spec get_latest(integer()) :: Ledger.t() | nil
  defp get_latest(asset_id) do
    Repo.one(from l in Ledger, where: l.asset_id == ^asset_id and l.latest == true)
  end

  @spec sell(Trade.t()) :: Multi.t()
  defp sell(%Trade{from_asset_id: nil}), do: Multi.new()

  defp sell(%Trade{
         id: trade_id,
         from_asset_id: from_asset_id,
         from_qty: from_qty,
         transacted_at: transacted_at,
         user_id: user_id
       }) do
    qty = from_qty |> Decimal.negate()
    latest_ledger = get_latest(from_asset_id)

    latest_weighted_average_cost =
      case latest_ledger do
        nil -> Decimal.new(1)
        ledger -> ledger.weighted_average_cost
      end

    latest_inventory_qty =
      case latest_ledger do
        nil -> Decimal.new(0)
        ledger -> ledger.inventory_qty
      end

    unit_cost = latest_weighted_average_cost
    total_cost = qty |> Utils.multiply(unit_cost)
    inventory_qty = latest_inventory_qty |> Decimal.add(qty)
    weighted_average_cost = latest_weighted_average_cost
    inventory_cost = inventory_qty |> Utils.multiply(weighted_average_cost)

    Multi.new()
    |> Multi.run(
      :update_sell_asset_latest_flag,
      fn repo, _ ->
        if latest_ledger == nil do
          {:ok, nil}
        else
          repo.update(Ledger.changeset(latest_ledger, %{latest: false}))
        end
      end
    )
    |> Multi.insert(
      :insert_sell_asset_latest_ledger,
      Ledger.changeset(%Ledger{}, %{
        inventory_qty: inventory_qty,
        inventory_cost: inventory_cost,
        weighted_average_cost: weighted_average_cost,
        unit_cost: unit_cost,
        total_cost: total_cost,
        qty: qty,
        transacted_at: transacted_at,
        latest: true,
        trade_id: trade_id,
        asset_id: from_asset_id,
        user_id: user_id
      })
    )
  end

  @spec buy(Trade.t(), Ledger.t()) :: Multi.t()
  defp buy(%Trade{to_asset_id: nil}, _sell_asset_latest_ledger), do: Multi.new()

  defp buy(
         %Trade{
           id: trade_id,
           to_qty: to_qty,
           to_asset_id: to_asset_id,
           transacted_at: transacted_at,
           user_id: user_id
         },
         sell_asset_latest_ledger
       ) do
    qty = to_qty

    root_asset = Assets.root(user_id)

    # In the case of dividends / free shares we sell nothing to get something hence sell_asset_latest_ledger = nil
    # - For dividends to ROOT asset we have to maintain the weighted average cost at $1 hence we set total_cost = qty
    # - All other cases total_cost is 0
    total_cost = total_cost(sell_asset_latest_ledger, to_asset_id, root_asset, qty)

    unit_cost = Boonorbust.Utils.divide(total_cost, qty)
    latest_ledger = get_latest(to_asset_id)

    latest_inventory_qty =
      case latest_ledger do
        nil -> Decimal.new(0)
        ledger -> ledger.inventory_qty
      end

    latest_inventory_cost =
      case latest_ledger do
        nil -> Decimal.new(0)
        ledger -> ledger.inventory_cost
      end

    inventory_qty = latest_inventory_qty |> Decimal.add(qty)
    inventory_cost = latest_inventory_cost |> Decimal.add(total_cost)
    weighted_average_cost = Boonorbust.Utils.divide(inventory_cost, inventory_qty)

    Multi.new()
    |> Multi.run(
      :update_buy_asset_latest_flag,
      fn repo, _ ->
        if latest_ledger == nil do
          {:ok, nil}
        else
          repo.update(Ledger.changeset(latest_ledger, %{latest: false}))
        end
      end
    )
    |> Multi.insert(
      :insert_buy_asset_latest_ledger,
      Ledger.changeset(%Ledger{}, %{
        inventory_qty: inventory_qty,
        inventory_cost: inventory_cost,
        weighted_average_cost: weighted_average_cost,
        unit_cost: unit_cost,
        total_cost: total_cost,
        qty: qty,
        transacted_at: transacted_at,
        latest: true,
        trade_id: trade_id,
        asset_id: to_asset_id,
        user_id: user_id
      })
    )
  end

  defp total_cost(sell_asset_latest_ledger, to_asset_id, root_asset, qty) do
    cond do
      # dividend to root currency
      sell_asset_latest_ledger == nil and root_asset.id == to_asset_id ->
        qty

      # dividend to on root currency / free shares
      sell_asset_latest_ledger == nil and root_asset.id != to_asset_id ->
        Decimal.new(0)

      # sell assets in exchange for root currency
      sell_asset_latest_ledger != nil and root_asset.id == to_asset_id ->
        qty

      # sell asset in exchange for non root currency / assets
      sell_asset_latest_ledger != nil and root_asset.id != to_asset_id ->
        sell_asset_latest_ledger.total_cost |> Decimal.abs()
    end
  end

  @spec all(integer(), integer()) :: [Ledger.t()]
  def all(user_id, asset_id) do
    Ledger
    |> where([l], l.user_id == ^user_id and l.asset_id == ^asset_id)
    |> order_by(asc: :id)
    |> preload(:trade)
    |> Repo.all()
  end

  @spec all_non_currency_latest(integer()) :: [Ledger.t()]
  def all_non_currency_latest(user_id) do
    Ledger
    |> join(:inner, [l], a in Asset, on: l.asset_id == a.id)
    |> preload([_l, a], asset: a)
    |> where(
      [l, a],
      l.user_id == ^user_id and l.latest == true and l.inventory_qty != 0 and a.type != :currency
    )
    |> Repo.all()
    |> calculate_price_value_profit(user_id)
    |> calculate_proportion()
    |> Enum.sort(fn %{profit_percent: pp1}, %{profit_percent: pp2} ->
      Decimal.compare(pp1, pp2) == :lt
    end)
  end

  defp calculate_price_value_profit(latest, user_id) do
    root_asset = Assets.root(user_id)

    usdsgd = exchange_rate("usdsgd")
    hkdsgd = exchange_rate("hkdsgd")

    latest
    |> Enum.map(fn ledger ->
      latest_price = latest_price(root_asset, ledger.asset)

      latest_price =
        cond do
          ledger.asset.code |> String.contains?("NYSE") or
            ledger.asset.code |> String.contains?("NASDAQ") or
            ledger.asset.code |> String.contains?("SGX:H78") or
              ledger.asset.type == :commodity ->
            latest_price |> Utils.multiply(usdsgd)

          ledger.asset.code |> String.contains?("HKEX") ->
            latest_price |> Utils.multiply(hkdsgd)

          true ->
            latest_price
        end

      latest_value = Decimal.new(latest_price) |> Utils.multiply(ledger.inventory_qty)

      profit_percent =
        latest_value
        |> Decimal.sub(ledger.inventory_cost)
        |> Boonorbust.Utils.divide(ledger.inventory_cost)
        |> Utils.multiply(Decimal.new(100))
        |> Decimal.round(2)

      ledger
      |> Map.put(:latest_price, latest_price)
      |> Map.put(:latest_value, latest_value)
      |> Map.put(:profit_percent, profit_percent)
    end)
  end

  defp calculate_proportion(latest) do
    total_value =
      latest
      |> Enum.reduce(Decimal.new(0), fn ledger, acc ->
        if ledger.asset.root do
          acc
        else
          acc |> Decimal.add(ledger.latest_value)
        end
      end)

    latest
    |> Enum.map(fn ledger ->
      latest_proportion =
        if ledger.asset.root,
          do: Decimal.new(0),
          else:
            ledger.latest_value
            |> Boonorbust.Utils.divide(total_value)
            |> Utils.multiply(Decimal.new(100))
            |> Decimal.round(2)

      ledger |> Map.put(:latest_proportion, latest_proportion)
    end)
  end

  @spec delete(integer()) :: {non_neg_integer(), nil | [term()]}
  def delete(user_id) do
    Ledger
    |> where([l], l.user_id == ^user_id)
    |> Repo.delete_all()
  end

  @spec exchange_rate(binary()) :: Decimal.t()
  def exchange_rate(currency_pair) do
    {:ok, %Finch.Response{body: body}} =
      Boonorbust.Http.get(
        "https://markets.ft.com/data/currencies/tearsheet/summary?s=#{currency_pair}"
      )

    Floki.parse_document!(body)
    |> Floki.find(".mod-ui-data-list__value")
    |> hd()
    |> Floki.text()
    |> String.replace(",", "")
    |> Decimal.new()
  end

  @spec latest_price(Asset.t(), Asset.t()) :: Decimal.t()
  defp latest_price(_root_asset, %Asset{type: :commodity, code: code}) do
    {:ok, %Finch.Response{body: body}} =
      Boonorbust.Http.get("https://markets.ft.com/data/commodities/tearsheet/summary?c=#{code}")

    Floki.parse_document!(body)
    |> Floki.find(".mod-ui-data-list__value")
    |> hd()
    |> Floki.text()
    |> String.replace(",", "")
    |> Decimal.new()
  end

  defp latest_price(_root_asset, %Asset{type: :fund, code: code}) do
    {:ok, %Finch.Response{body: body}} =
      Boonorbust.Http.get("https://markets.ft.com/data/funds/tearsheet/summary?s=#{code}:SGD")

    Floki.parse_document!(body)
    |> Floki.find(".mod-ui-data-list__value")
    |> hd()
    |> Floki.text()
    |> String.replace(",", "")
    |> Decimal.new()
  end

  defp latest_price(_root_asset, %Asset{type: :stock, code: code}) do
    {:ok, %Finch.Response{body: body}} =
      Boonorbust.Http.get("https://www.investingnote.com/stocks/#{code}")

    Floki.parse_document!(body)
    |> Floki.find("strong[class*='stock-price']")
    |> Floki.text()
    |> String.replace(",", "")
    |> Decimal.new()
  end

  defp latest_price(root_asset, %Asset{type: :crypto, code: code}) do
    {:ok, %Finch.Response{body: body}} =
      Boonorbust.Http.get(
        "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=#{code}&convert=#{root_asset.code}",
        [{"X-CMC_PRO_API_KEY", "b0b87191-9b14-434e-b0a8-bee99fed3b40"}]
      )

    "#{Jason.decode!(body)["data"][code]["quote"][root_asset.code]["price"]}"
    |> String.replace(",", "")
    |> Decimal.new()
  end

  defp latest_price(_root_asset, %Asset{type: :currency}), do: "1" |> Decimal.new()

  @spec profit_percent(integer(), list(Ledger.t())) :: Decimal.t()
  def profit_percent(_user_id, []), do: Decimal.new(0)

  def profit_percent(user_id, latest_ledgers) do
    {total_cost, total_value} =
      latest_ledgers
      |> Enum.reduce({Decimal.new(0), Decimal.new(0)}, fn l, {cost, value} ->
        if l.latest_value |> Decimal.negative?() do
          cost = l.latest_value |> Decimal.abs() |> Decimal.add(cost)
          {cost, value}
        else
          value = l.latest_value |> Decimal.add(value)
          {cost, value}
        end
      end)

    profit = total_value |> Decimal.sub(total_cost)

    _profit =
      Profits.upsert(%{
        date: Date.utc_today(),
        cost: total_cost,
        value: total_value,
        user_id: user_id
      })

    profit
    |> Boonorbust.Utils.divide(total_cost)
    |> Utils.multiply(Decimal.new(100))
    |> Decimal.round(2)
  end

  @spec portfolios(integer(), list(Ledger.t())) :: list(map())
  def portfolios(user_id, latest_ledgers) do
    portfolios = Portfolios.all(user_id)

    Enum.map(portfolios, fn portfolio ->
      tag_values = calculate_portfolio_tag_values(portfolio, latest_ledgers) |> add_percentage()
      %{name: portfolio.name, tag_values: tag_values}
    end)
  end

  defp add_percentage(tag_values) do
    total_value =
      Enum.reduce(tag_values, Decimal.new(0), fn %{value: value}, acc ->
        acc |> Decimal.add(value)
      end)

    tag_values
    |> Enum.map(fn tag_value ->
      percentage =
        tag_value.value
        |> Boonorbust.Utils.divide(total_value)
        |> Utils.multiply(Decimal.new(100))
        |> Decimal.round(2)

      tag_value |> Map.put_new(:percentage, percentage)
    end)
  end

  @spec calculate_portfolio_tag_values(Portfolio.t(), list(Ledger.t())) :: list(map())
  defp calculate_portfolio_tag_values(portfolio, latest_ledgers) do
    portfolio.tags
    |> Enum.map(fn tag ->
      asset_ids = tag.assets |> Enum.map(& &1.id)
      relevant_ledgers = latest_ledgers |> Enum.filter(fn l -> l.asset_id in asset_ids end)

      tag_value =
        relevant_ledgers
        |> Enum.reduce(Decimal.new(0), fn l, acc -> acc |> Decimal.add(l.latest_value) end)

      %{name: tag.name, value: tag_value}
    end)
  end
end
