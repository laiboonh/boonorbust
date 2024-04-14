defmodule Boonorbust.Assets do
  import Ecto.Query, warn: false

  alias Boonorbust.Assets.Asset
  alias Boonorbust.Repo

  @spec create(%{atom => any()}) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end

  @spec get(integer(), integer()) :: Asset.t() | nil
  def get(id, user_id) do
    Asset
    |> where([a], a.id == ^id and a.user_id == ^user_id)
    |> preload([a], :tags)
    |> Repo.one()
  end

  @spec update(integer(), integer(), map()) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t()}
  def update(id, user_id, attrs) do
    get(id, user_id)
    |> Asset.changeset(attrs)
    |> Repo.update()
  end

  @spec all(integer()) :: [Asset.t()]
  def all(user_id) do
    Asset
    |> where([a], a.user_id == ^user_id)
    |> preload([a], :tags)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @spec delete(integer(), integer()) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t()}
  def delete(id, user_id) do
    get(id, user_id)
    |> Repo.delete()
  end

  @spec root(integer()) :: Asset.t() | nil
  def root(user_id) do
    Asset
    |> where([a], a.user_id == ^user_id and a.root == true)
    |> Repo.one()
  end
end
