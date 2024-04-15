defmodule Boonorbust.ProfitsTest do
  use Boonorbust.DataCase
  alias Boonorbust.Profits

  import Boonorbust.AccountsFixtures

  describe "create" do
    test "creating profit" do
      user = user_fixture()

      assert {:ok, profit} =
               Profits.create(%{
                 value: Decimal.new(-123),
                 user_id: user.id,
                 date: Date.utc_today()
               })

      assert Profits.all(user.id) == [profit]
    end
  end
end
