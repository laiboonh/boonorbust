defmodule Boonorbust.TradesTest do
  use Boonorbust.DataCase
  alias Boonorbust.Assets
  alias Boonorbust.Trades

  import Boonorbust.AccountsFixtures

  describe "all_asc_trasacted_at" do
    test "sorted by transacted_at and id" do
      user = user_fixture()

      assert {:ok, usd} = Assets.create(%{name: "usd", user_id: user.id})
      assert {:ok, sgd} = Assets.create(%{name: "sgd", user_id: user.id, root: true})
      assert {:ok, apple} = Assets.create(%{name: "apple", user_id: user.id})

      {:ok, trade_1} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: usd.id,
          from_qty: 105,
          to_qty: 75,
          to_asset_unit_cost: 1.4,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      {:ok, trade_2} =
        Trades.create(%{
          from_asset_id: usd.id,
          to_asset_id: apple.id,
          from_qty: 75,
          to_qty: 75,
          to_asset_unit_cost: 1,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      assert Trades.all_asc_trasacted_at(user.id) == [trade_1, trade_2]
    end
  end
end
