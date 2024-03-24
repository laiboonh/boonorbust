defmodule Boonorbust.LedgersTest do
  use Boonorbust.DataCase
  alias Boonorbust.Assets
  alias Boonorbust.Ledgers
  alias Boonorbust.Trades

  import Boonorbust.AccountsFixtures

  describe "record" do
    test "success" do
      # spend 105 SGD (5 fee inclusive) to get 75 USD
      user = user_fixture()
      assert {:ok, usd} = Assets.create(%{name: "usd", user_id: user.id})
      assert {:ok, sgd} = Assets.create(%{name: "sgd", user_id: user.id})

      {:ok, trade} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: usd.id,
          from_qty: 105,
          to_qty: 75,
          to_asset_unit_cost: 1.4,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      {:ok, result} = Ledgers.record(trade)

      assert result.insert_sell_asset_latest_ledger.inventory_qty == Decimal.new(-105)
      assert result.insert_sell_asset_latest_ledger.inventory_cost == Decimal.new(-105)
      assert result.insert_sell_asset_latest_ledger.weighted_average_cost == Decimal.new(1)
      assert result.update_sell_asset_latest_flag == nil
      assert result.update_buy_asset_latest_flag == nil
      assert result.insert_buy_asset_latest_ledger.inventory_qty == Decimal.new(75)
      assert result.insert_buy_asset_latest_ledger.inventory_cost == Decimal.new(105)
      assert result.insert_buy_asset_latest_ledger.weighted_average_cost == Decimal.new("1.4")
    end
  end
end
