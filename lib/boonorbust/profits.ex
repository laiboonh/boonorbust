defmodule Boonorbust.Profits do
  import Ecto.Query, warn: false

  alias Boonorbust.Profits.Profit
  alias Boonorbust.Repo

  @spec upsert(%{atom => any()}) :: Profit.t()
  def upsert(%{date: date, value: value, cost: cost, user_id: user_id}) do
    Repo.insert!(
      %Boonorbust.Profits.Profit{date: date, value: value, cost: cost, user_id: user_id},
      on_conflict: [set: [value: value, cost: cost]],
      conflict_target: [:date, :user_id]
    )
  end

  @spec all(integer()) :: [Profit.t()]
  def all(user_id) do
    Profit
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], asc: p.date)
    |> Repo.all()
  end
end
