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

      assert {:ok, usd} =
               Assets.create(%{name: "usd", code: "usd", type: :currency, user_id: user.id})

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

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

      assert result.insert_sell_asset_latest_ledger.inventory_cost ==
               Decimal.new("-105.000000")

      assert result.insert_sell_asset_latest_ledger.weighted_average_cost == Decimal.new(1)
      assert result.update_sell_asset_latest_flag == nil
      assert result.update_buy_asset_latest_flag == nil
      assert result.insert_buy_asset_latest_ledger.inventory_qty == Decimal.new(75)
      assert result.insert_buy_asset_latest_ledger.inventory_cost == Decimal.new("105.000000")

      assert result.insert_buy_asset_latest_ledger.weighted_average_cost ==
               Decimal.new("1.400000")
    end

    test "success with fees (from something to nothing)" do
      # spend 105 SGD (5 fee inclusive) to get 75 USD
      user = user_fixture()

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

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
      assert sgd_latest.inventory_cost == Decimal.new("-1.230000")
      assert sgd_latest.unit_cost == Decimal.new("1")
      assert sgd_latest.weighted_average_cost == Decimal.new("1")
      assert sgd_latest.total_cost == Decimal.new("-1.230000")
    end

    test "success with dividends (from nothing to something)" do
      user = user_fixture()

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

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
      assert sgd_latest.unit_cost == Decimal.new("1.000000")
      assert sgd_latest.weighted_average_cost == Decimal.new("1.000000")
      assert sgd_latest.total_cost == Decimal.new("1.23")
      assert sgd_latest.total_cost == Decimal.new("1.23")
    end

    test "success with free shares / dividends that is not root asset (from nothing to something)" do
      # spend 105 SGD (5 fee inclusive) to get 75 USD
      user = user_fixture()

      assert {:ok, usd} =
               Assets.create(%{name: "usd", code: "usd", type: :currency, user_id: user.id})

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

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

      assert result.insert_buy_asset_latest_ledger.weighted_average_cost ==
               Decimal.new("1.400000")

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

    test "success with free shares and then selling it to root currency" do
      # spend 105 SGD (5 fee inclusive) to get 75 USD
      user = user_fixture()

      assert {:ok, apple} =
               Assets.create(%{name: "apple", code: "AAPL", type: :stock, user_id: user.id})

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

      # get 95 apple free shares
      {:ok, %{record: _result}} =
        Trades.create(%{
          from_asset_id: nil,
          to_asset_id: apple.id,
          from_qty: nil,
          to_qty: 95,
          to_asset_unit_cost: nil,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      {:ok, %{record: _result}} =
        Trades.create(%{
          from_asset_id: apple.id,
          to_asset_id: sgd.id,
          from_qty: 95,
          to_qty: 190,
          to_asset_unit_cost: 2,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      all_latest = Repo.all(Ledger |> where([l], l.latest == true))

      apple_latest = all_latest |> Enum.find(&(&1.asset_id == apple.id))
      sgd_latest = all_latest |> Enum.find(&(&1.asset_id == sgd.id))

      assert sgd_latest.weighted_average_cost == Decimal.new("1.000000")
      assert sgd_latest.inventory_qty == Decimal.new("190")
      assert sgd_latest.inventory_cost == Decimal.new("190")

      assert apple_latest.weighted_average_cost != Decimal.new("1.4")
      assert apple_latest.inventory_qty == Decimal.new("0")
      assert apple_latest.inventory_cost == Decimal.new("0.000000")
    end
  end

  describe "all_latest" do
    test "sold assets (inventory_qty = 0) are not returned" do
      user = user_fixture()

      assert {:ok, apple} =
               Assets.create(%{
                 name: "apple",
                 code: "AAPL",
                 type: :stock,
                 user_id: user.id
               })

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

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
      assert sgd_latest.inventory_cost == Decimal.new("95.000000")
      assert sgd_latest.weighted_average_cost == Decimal.new("1.000000")

      # Prevent test from calling actual endpoint
      expect(HttpBehaviourMock, :get, 2, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: """
           {
           "success": true,
           "timestamp": 1558310399,
           "historical": true,
           "base": "USD",
           "date": "2019-05-19",
           "rates": {
           "SGD": 1.23
           }
           }
           """
         }}
      end)

      [] = Boonorbust.Ledgers.all_non_currency_latest(user.id)
    end

    test "buy assets, currency is not returned" do
      user = user_fixture()

      assert {:ok, apple} =
               Assets.create(%{
                 name: "apple",
                 code: "AAPL",
                 type: :stock,
                 user_id: user.id
               })

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

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

      :ok = Ledgers.recalculate(user.id)

      # Prevent test from calling actual endpoint
      expect(HttpBehaviourMock, :get, 2, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: """
           {
           "success": true,
           "timestamp": 1558310399,
           "historical": true,
           "base": "USD",
           "date": "2019-05-19",
           "rates": {
           "SGD": 1.23
           }
           }
           """
         }}
      end)

      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           body: """
           <strong class="stock-price stock-up">227.790</strong>
           """
         }}
      end)

      [aapl_ledger] = Boonorbust.Ledgers.all_non_currency_latest(user.id)
      assert aapl_ledger.inventory_qty == Decimal.new("75")
      assert aapl_ledger.inventory_cost == Decimal.new("105.000000")
      assert aapl_ledger.weighted_average_cost == Decimal.new("1.400000")
      assert aapl_ledger.unit_cost == Decimal.new("1.400000")
      assert aapl_ledger.total_cost == Decimal.new("105.000000")
      assert aapl_ledger.qty == Decimal.new("75")
      assert aapl_ledger.transacted_at == Date.utc_today()
      assert aapl_ledger.latest == true
    end
  end

  describe "profit_percent" do
    test "success" do
      user = user_fixture()

      assert {:ok, apple} =
               Assets.create(%{
                 name: "apple",
                 code: "AAPL",
                 type: :stock,
                 user_id: user.id
               })

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

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

      :ok = Ledgers.recalculate(user.id)

      # Prevent test from calling actual endpoint
      expect(HttpBehaviourMock, :get, 2, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: """
           {
           "success": true,
           "timestamp": 1558310399,
           "historical": true,
           "base": "USD",
           "date": "2019-05-19",
           "rates": {
           "SGD": 1.23
           }
           }
           """
         }}
      end)

      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           body: """
           <strong class="stock-price stock-up">1.5</strong>
           """
         }}
      end)

      all_non_currency_latest = Boonorbust.Ledgers.all_non_currency_latest(user.id)
      # 1.4 to 1.5 = 7.14%
      assert Boonorbust.Ledgers.profit_percent(user.id, all_non_currency_latest) ==
               Decimal.new("7.14")
    end
  end
end
