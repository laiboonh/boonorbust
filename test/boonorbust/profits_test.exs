defmodule Boonorbust.ProfitsTest do
  use Boonorbust.DataCase
  alias Boonorbust.Profits

  import Boonorbust.AccountsFixtures

  describe "create" do
    test "creating profit" do
      user = user_fixture()

      profit = Profits.upsert(Date.utc_today(), Decimal.new(-123), user.id)

      assert Profits.all(user.id) == [profit]

      profit = Profits.upsert(Date.utc_today(), Decimal.new(123), user.id)

      assert Profits.all(user.id) == [profit]

      tomorrow_profit = Profits.upsert(Date.utc_today() |> Date.add(1), Decimal.new(123), user.id)

      assert Profits.all(user.id) == [profit, tomorrow_profit]
    end
  end
end
