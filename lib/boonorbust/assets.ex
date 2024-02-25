defmodule Boonorbust.Assets do
  import Ecto.Query, warn: false
  alias Boonorbust.Repo

  alias Boonorbust.Assets.Asset

  @spec create(%{atom => any()}) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end
end
