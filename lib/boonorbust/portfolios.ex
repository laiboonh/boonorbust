defmodule Boonorbust.Portfolios do
  import Ecto.Query, warn: false

  alias Boonorbust.Portfolios.Portfolio
  alias Boonorbust.Repo

  @spec create(%{atom => any()}) :: {:ok, Portfolio.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Portfolio{}
    |> Portfolio.changeset(attrs)
    |> Repo.insert()
  end

  @spec get(integer(), integer()) :: Portfolio.t() | nil
  def get(id, user_id) do
    Portfolio
    |> where([a], a.id == ^id and a.user_id == ^user_id)
    |> preload([a], :tags)
    |> Repo.one()
  end

  @spec update(integer(), integer(), map()) :: {:ok, Portfolio.t()} | {:error, Ecto.Changeset.t()}
  def update(id, user_id, attrs) do
    get(id, user_id)
    |> Portfolio.changeset(attrs)
    |> Repo.update()
  end

  @spec all(integer()) :: [Portfolio.t()]
  def all(user_id) do
    Portfolio
    |> where([a], a.user_id == ^user_id)
    |> preload([a], :tags)
    |> Repo.all()
  end

  @spec delete(integer(), integer()) :: {:ok, Portfolio.t()} | {:error, Ecto.Changeset.t()}
  def delete(id, user_id) do
    get(id, user_id)
    |> Repo.delete()
  end
end
