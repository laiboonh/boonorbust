defmodule Boonorbust.LedgersTest do
  use Boonorbust.DataCase

  alias Boonorbust.Assets
  alias Boonorbust.Ledgers
  alias Boonorbust.Ledgers.Ledger
  alias Boonorbust.Trades

  import Boonorbust.AccountsFixtures
  import Mox

  setup :verify_on_exit!

  describe "record" do
    test "success" do
      # spend 105 SGD (5 fee inclusive) to get 75 USD
      user = user_fixture()
      assert {:ok, usd} = Assets.create(%{name: "usd", user_id: user.id})
      assert {:ok, sgd} = Assets.create(%{name: "sgd", user_id: user.id, root: true})

      {:ok, %{record: result}} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: usd.id,
          from_qty: 105,
          to_qty: 75,
          to_asset_unit_cost: 1.4,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      assert result.insert_sell_asset_latest_ledger.inventory_qty == Decimal.new(-105)
      assert result.insert_sell_asset_latest_ledger.inventory_cost == Decimal.new(-105)
      assert result.insert_sell_asset_latest_ledger.weighted_average_cost == Decimal.new(1)
      assert result.update_sell_asset_latest_flag == nil
      assert result.update_buy_asset_latest_flag == nil
      assert result.insert_buy_asset_latest_ledger.inventory_qty == Decimal.new(75)
      assert result.insert_buy_asset_latest_ledger.inventory_cost == Decimal.new(105)
      assert result.insert_buy_asset_latest_ledger.weighted_average_cost == Decimal.new("1.4")
    end

    test "success with fees (from something to nothing)" do
      # spend 105 SGD (5 fee inclusive) to get 75 USD
      user = user_fixture()
      assert {:ok, sgd} = Assets.create(%{name: "sgd", user_id: user.id, root: true})

      # spend 1.23 SGD on Fees
      {:ok, _} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: nil,
          from_qty: 1.23,
          to_qty: nil,
          to_asset_unit_cost: nil,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      [sgd_latest] = Repo.all(Ledger)

      assert sgd_latest.inventory_qty == Decimal.new("-1.23")
      assert sgd_latest.inventory_cost == Decimal.new("-1.23")
      assert sgd_latest.unit_cost == Decimal.new("1")
      assert sgd_latest.weighted_average_cost == Decimal.new("1")
      assert sgd_latest.total_cost == Decimal.new("-1.23")
      assert sgd_latest.total_cost == Decimal.new("-1.23")
    end

    test "success with dividends (from nothing to something)" do
      user = user_fixture()
      assert {:ok, sgd} = Assets.create(%{name: "sgd", user_id: user.id, root: true})

      # get 1.23 SGD dividends
      {:ok, %{record: _result}} =
        Trades.create(%{
          from_asset_id: nil,
          to_asset_id: sgd.id,
          from_qty: nil,
          to_qty: 1.23,
          to_asset_unit_cost: nil,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      [sgd_latest] = Repo.all(Ledger)

      assert sgd_latest.inventory_qty == Decimal.new("1.23")
      assert sgd_latest.inventory_cost == Decimal.new("1.23")
      assert sgd_latest.unit_cost == Decimal.new("1")
      assert sgd_latest.weighted_average_cost == Decimal.new("1")
      assert sgd_latest.total_cost == Decimal.new("1.23")
      assert sgd_latest.total_cost == Decimal.new("1.23")
    end

    test "success with free shares / dividends that is not root asset (from nothing to something)" do
      # spend 105 SGD (5 fee inclusive) to get 75 USD
      user = user_fixture()
      assert {:ok, usd} = Assets.create(%{name: "usd", user_id: user.id})
      assert {:ok, sgd} = Assets.create(%{name: "sgd", user_id: user.id, root: true})

      {:ok, %{record: result}} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: usd.id,
          from_qty: 105,
          to_qty: 75,
          to_asset_unit_cost: 1.4,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      assert result.insert_buy_asset_latest_ledger.weighted_average_cost == Decimal.new("1.4")

      # get 1.23 USD dividends
      {:ok, %{record: _result}} =
        Trades.create(%{
          from_asset_id: nil,
          to_asset_id: usd.id,
          from_qty: nil,
          to_qty: 1.23,
          to_asset_unit_cost: nil,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      all_latest = Repo.all(Ledger |> where([l], l.latest == true))

      usd_latest = all_latest |> Enum.find(&(&1.asset_id == usd.id))
      sgd_latest = all_latest |> Enum.find(&(&1.asset_id == sgd.id))

      assert sgd_latest.weighted_average_cost == Decimal.new("1")

      # Because its not root asset any free shares or dividends to non root asset causues weighted average to drop
      assert usd_latest.weighted_average_cost != Decimal.new("1.4")
    end
  end

  describe "all_latest" do
    test "sold assets (inventory_qty = 0) are not returned" do
      user = user_fixture()
      assert {:ok, apple} = Assets.create(%{name: "apple", user_id: user.id, code: "apple"})
      assert {:ok, sgd} = Assets.create(%{name: "sgd", user_id: user.id, root: true, code: "sgd"})

      {:ok, _result} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: apple.id,
          from_qty: 105,
          to_qty: 75,
          to_asset_unit_cost: 1.4,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      {:ok, _result} =
        Trades.create(%{
          from_asset_id: apple.id,
          to_asset_id: sgd.id,
          from_qty: 75,
          to_qty: 200,
          to_asset_unit_cost: 2.5,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      :ok = Ledgers.recalculate(user.id)

      all_latest = Repo.all(Ledger |> where([l], l.latest == true))

      apple_latest = all_latest |> Enum.find(&(&1.asset_id == apple.id))
      sgd_latest = all_latest |> Enum.find(&(&1.asset_id == sgd.id))

      assert apple_latest.inventory_qty == Decimal.new(0)
      # Sold for: 75 * 2.5 = 200
      # Bought using: -105
      assert sgd_latest.inventory_qty == Decimal.new(95)
      assert sgd_latest.inventory_cost == Decimal.new(95)
      assert sgd_latest.weighted_average_cost == Decimal.new("1")

      # Prevent test from calling actual endpoint
      expect(HttpBehaviourMock, :get, 2, fn _url ->
        {:ok,
         %Finch.Response{
           body: """
           <span class="mod-ui-data-list__value">1.23</span>
           """
         }}
      end)

      [sgd_latest_ledger] = Boonorbust.Ledgers.all_latest(user.id)

      assert sgd_latest_ledger.latest_price == Decimal.new("1")
      assert sgd_latest_ledger.latest_value == Decimal.new("95")
      assert sgd_latest_ledger.profit_percent == Decimal.new("0.00")
    end
  end
end
