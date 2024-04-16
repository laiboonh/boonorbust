defmodule Boonorbust.Profits do
  import Ecto.Query, warn: false

  alias Boonorbust.Profits.Profit
  alias Boonorbust.Repo

  @spec upsert(Date.t(), Decimal.t(), integer()) :: Profit.t()
  def upsert(date, value, user_id) do
    Repo.insert!(
      %Boonorbust.Profits.Profit{date: date, value: value, user_id: user_id},
      on_conflict: [set: [value: value]],
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
