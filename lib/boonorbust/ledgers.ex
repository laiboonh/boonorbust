defmodule Boonorbust.Ledgers do
  import Ecto.Query, warn: false

  alias Boonorbust.Ledgers.Ledger
  alias Boonorbust.Repo
  alias Boonorbust.Trades.Trade
  alias Ecto.Multi

  @spec create(%{atom => any()}) :: {:ok, Ledger.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Ledger{}
    |> Ledger.changeset(attrs)
    |> Repo.insert()
  end

  @spec record(Trade.t()) :: {:ok, any()} | {:error, any()} | Ecto.Multi.failure()
  def record(trade) do
    sell(trade)
    |> Multi.merge(fn %{insert_sell_asset_latest_ledger: sell_asset_latest_ledger} ->
      buy(trade, sell_asset_latest_ledger)
    end)
    |> Repo.transaction()
  end

  @spec get_latest(integer()) :: Ledger.t() | nil
  defp get_latest(id) do
    Repo.one(from l in Ledger, where: l.asset_id == ^id and l.latest == true)
  end

  @spec sell(Trade.t()) :: Multi.t()
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
  defp buy(
         %Trade{
           id: trade_id,
           to_qty: to_qty,
           to_asset_id: to_asset_id
         },
         sell_asset_latest_ledger
       ) do
    qty = to_qty
    total_cost = sell_asset_latest_ledger.total_cost |> Decimal.abs()
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
end
