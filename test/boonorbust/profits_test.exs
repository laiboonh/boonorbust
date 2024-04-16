defmodule Boonorbust.ProfitsTest do
  use Boonorbust.DataCase
  alias Boonorbust.Profits

  import Boonorbust.AccountsFixtures

  describe "create" do
    test "creating profit" do
      user = user_fixture()

      assert profit = Profits.upsert(Date.utc_today(), Decimal.new(-123), user.id)

      assert Profits.all(user.id) == [profit]

      assert profit = Profits.upsert(Date.utc_today(), Decimal.new(123), user.id)

      assert Profits.all(user.id) == [profit]
    end
  end
end
