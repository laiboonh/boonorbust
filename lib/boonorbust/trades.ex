defmodule Boonorbust.Trades do
  import Ecto.Query, warn: false

  alias Boonorbust.Assets
  alias Boonorbust.Assets.Asset
  alias Boonorbust.ExchangeRates
  alias Boonorbust.Ledgers
  alias Boonorbust.Repo
  alias Boonorbust.Trades.Trade
  alias Ecto.Multi

  @spec create(%{atom => any()}) :: {:ok, any()} | {:error, any()} | Ecto.Multi.failure()
  def create(attrs) do
    multi =
      Multi.new()
      |> Multi.run(:currency_exchange, fn _repo, _changes ->
        maybe_create_currency_exchange_trade(attrs)
      end)
      |> Multi.insert(
        :insert,
        %Trade{}
        |> Trade.changeset(attrs)
      )

    Repo.transaction(multi)
  end

  defp maybe_create_currency_exchange_trade(%{
         from_asset_id: from_asset_id,
         from_qty: from_qty,
         transacted_at: transacted_at,
         user_id: user_id
       }) do
    from_asset = if from_asset_id == nil, do: nil, else: Assets.get(from_asset_id, user_id)
    local_currency = Assets.root(user_id)

    if from_asset != nil && from_asset.type == :currency && from_asset.id != local_currency.id do
      foreign_currency = from_asset
      foreign_currency_amount_needed = from_qty

      [{_foreign_currency_name, %{total_qty: foreign_currency_amount_held}}] =
        Ledgers.all(user_id, foreign_currency.id).trades_by_from_asset_code

      if Decimal.gt?(foreign_currency_amount_held, foreign_currency_amount_needed) ||
           Decimal.eq?(foreign_currency_amount_held, foreign_currency_amount_needed) do
        # Enough foreign currency to support trade. No exchange needed
        {:ok, nil}
      else
        # Not enough, how much more is neded?
        foreign_currency_amount_needed =
          foreign_currency_amount_needed |> Decimal.sub(foreign_currency_amount_held)

        exchange_rate =
          ExchangeRates.get_exchange_rate(
            local_currency.code,
            foreign_currency.code,
            transacted_at
          )

        local_currency_amount_needed =
          Boonorbust.Utils.divide(foreign_currency_amount_needed, exchange_rate)

        create(%{
          from_asset_id: local_currency.id,
          to_asset_id: foreign_currency.id,
          from_qty: local_currency_amount_needed,
          to_qty: foreign_currency_amount_needed,
          to_asset_unit_cost: exchange_rate,
          transacted_at: transacted_at,
          user_id: user_id
        })
      end
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
    filter = Map.get(attrs, :filter, "")

    filter_where_attrs =
      if filter != "" do
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
    |> join(:left, [t], fa in Asset, on: t.from_asset_id == fa.id)
    |> join(:left, [t, fa], ta in Asset, on: t.to_asset_id == ta.id)
    |> where([t, fa, ta], t.user_id == ^user_id)
    |> where([t, fa, ta], ^filter_where(filter_where_attrs))
    |> order_by(desc: :transacted_at)
    |> Repo.paginate(attrs)
  end

  @spec all_to_and_from_asset(integer(), integer()) :: [Trade.t()]
  def all_to_and_from_asset(user_id, asset_id) do
    Trade
    |> join(:left, [t], ta in Asset, on: t.to_asset_id == ta.id)
    |> join(:left, [t, ta], fa in Asset, on: t.from_asset_id == fa.id)
    |> where([t, ta, fa], t.user_id == ^user_id and (ta.id == ^asset_id or fa.id == ^asset_id))
    |> preload([_t, _ta, _fa], [:from_asset, :to_asset])
    |> Repo.all()
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
