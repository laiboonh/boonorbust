defmodule Boonorbust.Tags do
  import Ecto.Query, warn: false

  alias Boonorbust.Repo
  alias Boonorbust.Tags.Tag

  @spec create(%{atom => any()}) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @spec get(integer(), integer()) :: Tag.t() | nil
  def get(id, user_id) do
    Tag
    |> where([t], t.id == ^id and t.user_id == ^user_id)
    |> Repo.one()
  end

  @spec update(integer(), integer(), map()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def update(id, user_id, attrs) do
    get(id, user_id)
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @spec all(integer()) :: [Tag.t()]
  def all(user_id) do
    Tag
    |> where([t], t.user_id == ^user_id)
    |> order_by(asc: :name)
    |> Repo.all()
  end

  @spec delete(integer(), integer()) :: {:ok, Tag.t()} | {:error, Ecto.Changeset.t()}
  def delete(id, user_id) do
    get(id, user_id)
    |> Repo.delete()
  end
end
