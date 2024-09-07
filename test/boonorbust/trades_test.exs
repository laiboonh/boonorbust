defmodule Boonorbust.TradesTest do
  alias Boonorbust.Ledgers
  use Boonorbust.DataCase
  alias Boonorbust.Assets
  alias Boonorbust.Trades

  import Boonorbust.AccountsFixtures
  import Mox
  setup :verify_on_exit!

  describe "create" do
    test "success" do
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

      {:ok, _trade} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: usd.id,
          from_qty: "105",
          to_qty: "75",
          to_asset_unit_cost: "1.4",
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      [usd_ledger] = Ledgers.all(user.id, usd.id)
      assert usd_ledger.inventory_qty == Decimal.new("75")
      assert usd_ledger.inventory_cost == Decimal.new("105")

      [usd_ledger] = Ledgers.all(user.id, sgd.id)
      assert usd_ledger.inventory_qty == Decimal.new("-105")
      assert usd_ledger.inventory_cost == Decimal.new("-105")
    end

    test "success with auto_create trade" do
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

      assert {:ok, apple} =
               Assets.create(%{name: "apple", code: "appl", type: :stock, user_id: user.id})

      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: """
           {
           "success": true,
           "timestamp": 1558310399,
           "historical": true,
           "base": "SGD",
           "date": "2019-05-19",
           "rates": {
           "USD": 0.726438
           }
           }
           """
         }}
      end)

      {:ok, _trade} =
        Trades.create(
          %{
            from_asset_id: usd.id,
            to_asset_id: apple.id,
            from_qty: "105",
            to_qty: "75",
            to_asset_unit_cost: "1.4",
            transacted_at: Date.utc_today(),
            user_id: user.id
          },
          true
        )

      [sgd_ledger] = Ledgers.all(user.id, sgd.id)

      assert sgd_ledger.weighted_average_cost == Decimal.new("1")
      assert sgd_ledger.qty == Decimal.new("-144.5408968143186342124173020")

      assert Ledgers.all(user.id, usd.id) |> length() == 2

      [apple_ledger] = Ledgers.all(user.id, apple.id)

      assert apple_ledger.total_cost == Decimal.new("144.5408968143186342124173020")
      assert apple_ledger.qty == Decimal.new("75")
    end
  end

  describe "all_asc_trasacted_at" do
    test "sorted by transacted_at and id" do
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

      assert {:ok, apple} =
               Assets.create(%{name: "apple", code: "AAPL", type: :stock, user_id: user.id})

      {:ok, %{insert: trade_1}} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: usd.id,
          from_qty: "105",
          to_qty: "75",
          to_asset_unit_cost: "1.4",
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      {:ok, %{insert: trade_2}} =
        Trades.create(%{
          from_asset_id: usd.id,
          to_asset_id: apple.id,
          from_qty: "75",
          to_qty: "75",
          to_asset_unit_cost: "1",
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      assert Trades.all_asc_trasacted_at(user.id) == [trade_1, trade_2]
    end
  end

  describe "all" do
    test "paging" do
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

      1..11
      |> Enum.each(fn num ->
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: usd.id,
          from_qty: 105,
          to_qty: 75,
          to_asset_unit_cost: 1.4,
          transacted_at: Date.utc_today() |> Date.add(num),
          user_id: user.id
        })
      end)

      assert Trades.all(user.id, %{page: 1, page_size: 10}).entries |> length() == 10

      assert Trades.all(user.id, %{page: 2, page_size: 10}).entries |> length() == 1
    end
  end
end
