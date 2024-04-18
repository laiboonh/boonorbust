defmodule Boonorbust.ProfitsTest do
  use Boonorbust.DataCase
  alias Boonorbust.Profits

  import Boonorbust.AccountsFixtures

  describe "create" do
    test "creating profit" do
      user = user_fixture()

      profit =
        Profits.upsert(%{
          date: Date.utc_today(),
          cost: Decimal.new(-123),
          value: Decimal.new(123),
          user_id: user.id
        })

      assert Profits.all(user.id) == [profit]

      profit =
        Profits.upsert(%{
          date: Date.utc_today(),
          cost: Decimal.new(-246),
          value: Decimal.new(123),
          user_id: user.id
        })

      assert Profits.all(user.id) == [profit]

      tomorrow_profit =
        Profits.upsert(%{
          date: Date.utc_today() |> Date.add(1),
          cost: Decimal.new(-123),
          value: Decimal.new(0),
          user_id: user.id
        })

      assert Profits.all(user.id) == [profit, tomorrow_profit]
    end
  end
end
