defmodule Boonorbust.TradesTest do
  alias Boonorbust.Ledgers
  use Boonorbust.DataCase
  alias Boonorbust.Assets
  alias Boonorbust.Trades

  import Boonorbust.AccountsFixtures
  import Mox
  setup :verify_on_exit!

  describe "create" do
    test "success with no currency exchange needed (more than amount needed)" do
      user = user_fixture()

      assert {:ok, usd} =
               Assets.create(%{name: "usd", code: "usd", type: :currency, user_id: user.id})

      assert {:ok, apple} =
               Assets.create(%{name: "apple", code: "appl", type: :stock, user_id: user.id})

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

      expect(HttpBehaviourMock, :get, fn _url, _headers ->
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
           "SGD": 1.25
           }
           }
           """
         }}
      end)

      {:ok, _trade} =
        Trades.create(%{
          from_asset_id: usd.id,
          to_asset_id: apple.id,
          from_qty: "50",
          to_qty: "1",
          to_asset_unit_cost: "50",
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      # No need for a second exchange rate mock call because rate is cached in DB from first call
      [{"usd", %{total_qty: total_qty, total_cost: total_cost}}] =
        Ledgers.all(user.id, usd.id).trades_by_from_asset_code

      # 75 - 50 = 25 usd
      assert total_cost == Decimal.new("25")
      assert total_qty == Decimal.new("25")

      ledgers = Ledgers.all(user.id, usd.id)
      # 75 * 1.25 = 31.25 sgd
      assert ledgers.grand_total_cost == Decimal.new("31.250000")
      assert ledgers.grand_total_qty == Decimal.new("31.250000")
    end

    test "success with no currency exchange needed (exact amount needed)" do
      user = user_fixture()

      assert {:ok, usd} =
               Assets.create(%{name: "usd", code: "usd", type: :currency, user_id: user.id})

      assert {:ok, apple} =
               Assets.create(%{name: "apple", code: "appl", type: :stock, user_id: user.id})

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

      expect(HttpBehaviourMock, :get, fn _url, _headers ->
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
           "SGD": 1.25
           }
           }
           """
         }}
      end)

      {:ok, _trade} =
        Trades.create(%{
          from_asset_id: usd.id,
          to_asset_id: apple.id,
          from_qty: "75",
          to_qty: "1",
          to_asset_unit_cost: "75",
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      # No need for a second exchange rate mock call because rate is cached in DB from first call
      [{"usd", %{total_qty: total_qty, total_cost: total_cost}}] =
        Ledgers.all(user.id, usd.id).trades_by_from_asset_code

      # 75 - 75 = 0 usd
      assert total_cost == Decimal.new("0")
      assert total_qty == Decimal.new("0")

      ledgers = Ledgers.all(user.id, usd.id)
      # 0 usd = 0 sgd
      assert ledgers.grand_total_cost == Decimal.new("0.000000")
      assert ledgers.grand_total_qty == Decimal.new("0.000000")
    end

    test "success with currency exchange trade" do
      user = user_fixture()

      assert {:ok, usd} =
               Assets.create(%{name: "usd", code: "usd", type: :currency, user_id: user.id})

      assert {:ok, apple} =
               Assets.create(%{name: "apple", code: "appl", type: :stock, user_id: user.id})

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

      expect(HttpBehaviourMock, :get, fn url, _headers ->
        assert url |> String.ends_with?("base=USD")

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
           "SGD": 1.25
           }
           }
           """
         }}
      end)

      expect(HttpBehaviourMock, :get, fn url, _headers ->
        assert url |> String.ends_with?("base=SGD")

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
           "USD": 0.8
           }
           }
           """
         }}
      end)

      {:ok, _trade} =
        Trades.create(%{
          from_asset_id: usd.id,
          to_asset_id: apple.id,
          from_qty: "100",
          to_qty: "1",
          to_asset_unit_cost: "100",
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      # No need for a second exchange rate mock call because rate is cached in DB from first call
      ledgers = Ledgers.all(user.id, usd.id)
      assert ledgers.grand_total_cost == Decimal.new("0.000000")

      # 105 SGD + (25 USD -> 31.25 SGD) =  136.25 SGD spent
      ledgers = Ledgers.all(user.id, sgd.id)
      assert ledgers.grand_total_qty == Decimal.new("-136.250000")
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

      expect(HttpBehaviourMock, :get, fn _url, _headers ->
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
           "SGD": 1.25
           }
           }
           """
         }}
      end)

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

    test "filter" do
      user = user_fixture()

      assert {:ok, _usd} =
               Assets.create(%{name: "usd", code: "usd", type: :currency, user_id: user.id})

      assert {:ok, sgd} =
               Assets.create(%{
                 name: "sgd",
                 code: "sgd",
                 type: :currency,
                 user_id: user.id,
                 root: true
               })

      assert {:ok, baba} =
               Assets.create(%{
                 name: "BABA",
                 code: "HKEX:9988",
                 type: :currency,
                 user_id: user.id
               })

      Trades.create(%{
        from_asset_id: sgd.id,
        to_asset_id: baba.id,
        from_qty: 105,
        to_qty: 75,
        to_asset_unit_cost: 1.4,
        transacted_at: Date.utc_today(),
        user_id: user.id
      })

      assert Trades.all(user.id, %{filter: "ba"}).entries |> length() == 1
      assert Trades.all(user.id, %{filter: "SG"}).entries |> length() == 1
    end
  end
end
