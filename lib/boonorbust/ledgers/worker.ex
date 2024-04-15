defmodule Boonorbust.Ledgers.Worker do
  use Oban.Worker

  alias Boonorbust.Accounts
  alias Boonorbust.Ledgers
  alias Boonorbust.Profits

  @impl Oban.Worker
  def perform(_job) do
    Accounts.all()
    |> Enum.each(fn user ->
      today = Date.utc_today()
      all_latest = Ledgers.all_latest(user.id)
      profit = Ledgers.profit(all_latest)
      {:ok, _} = Profits.create(%{date: today, value: profit, user_id: user.id})
    end)
  end
end
