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

  @spec get(integer()) :: Trade.t() | nil
  def get(id) do
    Repo.get(Trade, id)
  end

  @spec update(any(), any()) :: {:ok, Trade.t()} | {:error, Ecto.Changeset.t()}
  def update(id, attrs) do
    get(id)
    |> Trade.changeset(attrs)
    |> Repo.update()
  end

  @spec all :: [Trade.t()]
  def all do
    Trade
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @spec delete(integer()) :: {:ok, Trade.t()} | {:error, Ecto.Changeset.t()}
  def delete(id) do
    get(id)
    |> Repo.delete()
  end
end
