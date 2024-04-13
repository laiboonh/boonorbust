defmodule Boonorbust.Ledgers do
  import Ecto.Query, warn: false

  alias Boonorbust.Assets
  alias Boonorbust.Ledgers.Ledger
  alias Boonorbust.Repo
  alias Boonorbust.Trades
  alias Boonorbust.Trades.Trade
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
  defp get_latest(id) do
    Repo.one(from l in Ledger, where: l.asset_id == ^id and l.latest == true)
  end

  @spec sell(Trade.t()) :: Multi.t()
  defp sell(%Trade{from_asset_id: nil}), do: Multi.new()

  defp sell(%Trade{id: trade_id, from_asset_id: from_asset_id, from_qty: from_qty}) do
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
    total_cost = qty |> Decimal.mult(unit_cost)
    inventory_qty = latest_inventory_qty |> Decimal.add(qty)
    weighted_average_cost = latest_weighted_average_cost
    inventory_cost = inventory_qty |> Decimal.mult(weighted_average_cost)

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
        latest: true,
        trade_id: trade_id,
        asset_id: from_asset_id
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
           user_id: user_id
         },
         sell_asset_latest_ledger
       ) do
    qty = to_qty

    # In the case of dividends we sell nothing to get something hence sell_asset_latest_ledger = nil
    # In the case of sell asset to root asset (SGD)
    root_asset = Assets.root(user_id)

    total_cost =
      if sell_asset_latest_ledger == nil or root_asset.id == to_asset_id,
        do: qty,
        else: sell_asset_latest_ledger.total_cost |> Decimal.abs()

    unit_cost = total_cost |> Decimal.div(qty)
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
    weighted_average_cost = inventory_cost |> Decimal.div(inventory_qty)

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
        latest: true,
        trade_id: trade_id,
        asset_id: to_asset_id
      })
    )
  end

  @spec all(integer(), integer()) :: [Ledger.t()]
  def all(user_id, asset_id) do
    Ledger
    |> join(:inner, [l], t in assoc(l, :trade))
    |> where([l, t], t.user_id == ^user_id and l.asset_id == ^asset_id)
    |> order_by(asc: :id)
    |> preload(:trade)
    |> Repo.all()
  end

  @spec all_latest(integer()) :: [Ledger.t()]
  def all_latest(user_id) do
    root_asset = Assets.root(user_id)

    Ledger
    |> join(:inner, [l], t in assoc(l, :trade))
    |> where([l, t], t.user_id == ^user_id and l.latest == true and l.inventory_qty != 0)
    |> preload(:asset)
    |> Repo.all()
    |> Enum.map(fn ledger ->
      Map.put(ledger, :latest_price, latest_price(root_asset, ledger.asset.code))
    end)
  end

  @spec delete(integer()) :: {non_neg_integer(), nil | [term()]}
  def delete(user_id) do
    Ledger
    |> join(:inner, [l], t in assoc(l, :trade))
    |> where([l, t], t.user_id == ^user_id)
    |> Repo.delete_all()
  end

  @spec latest_price(Asset.t(), binary()) :: binary()
  defp latest_price(_root_asset, "FUND." <> code) do
    {:ok, %Finch.Response{body: body}} =
      Finch.build(:get, "https://markets.ft.com/data/funds/tearsheet/summary?s=#{code}:SGD")
      |> Finch.request(Boonorbust.Finch)

    Floki.parse_document!(body)
    |> Floki.find(".mod-ui-data-list__value")
    |> hd()
    |> Floki.text()
  end

  defp latest_price(_root_asset, "STOCK." <> code) do
    {:ok, %Finch.Response{body: body}} =
      Finch.build(:get, "https://www.investingnote.com/stocks/#{code}")
      |> Finch.request(Boonorbust.Finch)

    Floki.parse_document!(body)
    |> Floki.find("strong[class*='stock-price']")
    |> Floki.text()
  end

  defp latest_price(root_asset, "TOKEN." <> code) do
    {:ok, %Finch.Response{body: body}} =
      Finch.build(
        :get,
        "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=#{code}&convert=#{root_asset.code}",
        [{"X-CMC_PRO_API_KEY", "b0b87191-9b14-434e-b0a8-bee99fed3b40"}]
      )
      |> Finch.request(Boonorbust.Finch)

    Jason.decode!(body)["data"][code]["quote"][root_asset.code]["price"]
  end

  defp latest_price(_root_asset, _code), do: "1"
end
