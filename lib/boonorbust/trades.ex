defmodule Boonorbust.Trades do
  import Ecto.Query, warn: false

  alias Boonorbust.Repo
  alias Boonorbust.Trades.Trade

  @spec create(%{atom => any()}) :: {:ok, Trade.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Trade{}
    |> Trade.changeset(attrs)
    |> Repo.insert()
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

  @spec all(integer()) :: [Trade.t()]
  def all(user_id) do
    Trade
    |> where([a], a.user_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @spec all_asc_trasacted_at(integer()) :: [Trade.t()]
  def all_asc_trasacted_at(user_id) do
    Trade
    |> where([a], a.user_id == ^user_id)
    |> order_by(asc: :transacted_at)
    |> Repo.all()
  end

  @spec delete(integer(), integer()) :: {:ok, Trade.t()} | {:error, Ecto.Changeset.t()}
  def delete(id, user_id) do
    get(id, user_id)
    |> Repo.delete()
  end
end
