defmodule Boonorbust.Profits do
  import Ecto.Query, warn: false

  alias Boonorbust.Profits.Profit
  alias Boonorbust.Repo

  @spec create(%{atom => any()}) :: {:ok, Profit.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Profit{}
    |> Profit.changeset(attrs)
    |> Repo.insert()
  end

  @spec all(integer()) :: [Profit.t()]
  def all(user_id) do
    Profit
    |> where([p], p.user_id == ^user_id)
    |> Repo.all()
  end
end
