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

  @spec get(integer()) :: Asset.t() | nil
  def get(id) do
    Repo.get(Asset, id)
  end

  @spec update(any(), any()) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t()}
  def update(id, attrs) do
    get(id)
    |> Asset.changeset(attrs)
    |> Repo.update()
  end

  @spec all :: [Asset.t()]
  def all do
    Asset
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  @spec delete(integer()) :: {:ok, Asset.t()} | {:error, Ecto.Changeset.t()}
  def delete(id) do
    get(id)
    |> Repo.delete()
  end
end