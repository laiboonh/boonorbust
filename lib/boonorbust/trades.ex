defmodule Boonorbust.Trades do
  import Ecto.Query, warn: false

  alias Boonorbust.Assets
  alias Boonorbust.Assets.Asset
  alias Boonorbust.ExchangeRates
  alias Boonorbust.Ledgers
  alias Boonorbust.Repo
  alias Boonorbust.Trades.Trade
  alias Ecto.Changeset
  alias Ecto.Multi

  @spec create(%{atom => any()}, boolean()) ::
          {:ok, any()} | {:error, any()} | Ecto.Multi.failure()
  def create(attrs, auto_create \\ false) do
    multi =
      if auto_create do
        Multi.new()
        |> Multi.run(:auto_create, fn _repo, _changes -> maybe_auto_create_trade(attrs) end)
        |> Multi.insert(
          :insert,
          %Trade{}
          |> Trade.changeset(attrs)
        )
        |> Multi.run(:record, fn _repo, %{insert: trade} -> Ledgers.record(trade) end)
      else
        Multi.new()
        |> Multi.insert(
          :insert,
          %Trade{}
          |> Trade.changeset(attrs)
        )
        |> Multi.run(:record, fn _repo, %{insert: trade} -> Ledgers.record(trade) end)
      end

    Repo.transaction(multi)
  end

  @spec maybe_auto_create_trade(map()) :: {:ok, Trade.t() | nil} | {:error, Changeset.t()}
  defp maybe_auto_create_trade(%{
         from_asset_id: from_asset_id,
         from_qty: from_qty,
         to_asset_id: to_asset_id,
         user_id: user_id,
         transacted_at: transacted_at
       }) do
    root_asset = Assets.root(user_id)
    from_asset = Assets.get(from_asset_id, user_id)

    if from_asset_id != root_asset.id && to_asset_id != root_asset.id &&
         from_asset.type == :currency do
      to_asset_id = from_asset_id
      to_asset = from_asset

      exchange_rate =
        ExchangeRates.get_exchange_rate(root_asset.code, to_asset.code, transacted_at)

      to_qty = from_qty

      from_qty = Decimal.new(to_qty) |> Decimal.div(exchange_rate)

      create(%{
        from_asset_id: root_asset.id,
        to_asset_id: to_asset_id,
        from_qty: from_qty,
        to_qty: to_qty,
        to_asset_unit_cost: exchange_rate,
        transacted_at: transacted_at,
        user_id: user_id
      })
    else
      {:ok, nil}
    end
  end

  @spec get(integer(), integer()) :: Trade.t() | nil
  def get(id, user_id) do
    Trade
    |> where([a], a.id == ^id and a.user_id == ^user_id)
    |> Repo.one()
  end

  @spec update(integer(), integer(), map()) :: {:ok, Trade.t()} | {:error, Ecto.Changeset.t()}
  def update(id, user_id, attrs) do
    get(id, user_id)
    |> Trade.changeset(attrs)
    |> Repo.update()
  end

  @spec all(integer(), %{atom() => any()}) :: Scrivener.Page.t()
  def all(user_id, attrs \\ %{page: 1, page_size: 1}) do
    filter = Map.get(attrs, :filter)

    filter_where_attrs =
      if filter != nil do
        %{
          to_asset_name: filter,
          from_asset_name: filter,
          to_asset_code: filter,
          from_asset_code: filter
        }
      else
        nil
      end

    Trade
    |> join(:inner, [t], fa in Asset, on: t.from_asset_id == fa.id)
    |> join(:inner, [t, fa], ta in Asset, on: t.to_asset_id == ta.id)
    |> where([t, fa, ta], t.user_id == ^user_id)
    |> where([t, fa, ta], ^filter_where(filter_where_attrs))
    |> order_by(desc: :transacted_at)
    |> Repo.paginate(attrs)
  end

  def filter_where(nil), do: dynamic(true)

  def filter_where(attrs) do
    Enum.reduce(attrs, dynamic(false), fn
      {:to_asset_name, value}, dynamic ->
        dynamic([t, fa, ta], ^dynamic or ilike(ta.name, ^"%#{value}%"))

      {:from_asset_name, value}, dynamic ->
        dynamic([t, fa, ta], ^dynamic or ilike(fa.name, ^"%#{value}%"))

      {:to_asset_code, value}, dynamic ->
        dynamic([t, fa, ta], ^dynamic or ilike(ta.code, ^"%#{value}%"))

      {:from_asset_code, value}, dynamic ->
        dynamic([t, fa, ta], ^dynamic or ilike(fa.code, ^"%#{value}%"))
    end)
  end

  @spec all_asc_trasacted_at(integer()) :: [Trade.t()]
  def all_asc_trasacted_at(user_id) do
    Trade
    |> where([a], a.user_id == ^user_id)
    |> order_by([:transacted_at, :id])
    |> Repo.all()
  end

  @spec delete(integer(), integer()) :: {:ok, Trade.t()} | {:error, Ecto.Changeset.t()}
  def delete(id, user_id) do
    get(id, user_id)
    |> Repo.delete()
  end
end
