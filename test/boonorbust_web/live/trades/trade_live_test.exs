defmodule BoonorbustWeb.Trades.TradeLiveTest do
  alias Boonorbust.Trades
  use BoonorbustWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Boonorbust.AccountsFixtures
  import Boonorbust.AssetsFixtures

  describe "Insert" do
    test "success", %{conn: conn} do
      user = user_fixture()
      from_asset = asset_fixture(%{name: "SGD", user_id: user.id, root: true})
      to_asset = asset_fixture(%{name: "USD", user_id: user.id, root: false})

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/trades/new")

      result =
        lv
        |> form("#trade_form",
          trade: %{
            "from_asset_id" => from_asset.id,
            "from_qty" => 1,
            "to_asset_id" => to_asset.id,
            "to_qty" => 1,
            "user_id" => user.id,
            "to_asset_unit_cost" => 1,
            "transacted_at" => "2024-03-15"
          }
        )
        |> render_submit()

      assert result =~ ~r/Trade \d+ Inserted/
    end
  end

  describe "Update" do
    test "success", %{conn: conn} do
      user = user_fixture()
      from_asset = asset_fixture(%{name: "SGD", user_id: user.id, root: true})
      to_asset = asset_fixture(%{name: "USD", user_id: user.id, root: false})

      {:ok, %{insert: trade}} =
        Trades.create(%{
          "from_asset_id" => from_asset.id,
          "from_qty" => 1,
          "to_asset_id" => to_asset.id,
          "to_qty" => 1,
          "user_id" => user.id,
          "to_asset_unit_cost" => 1,
          "transacted_at" => "2024-03-15"
        })

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/trades/#{trade.id}")

      result =
        lv
        |> form("#trade_form",
          trade: %{"transacted_at" => "2024-04-15"}
        )
        |> render_submit()

      assert result =~ ~r/Trade \d+ Updated/
      assert Trades.get(trade.id, user.id).transacted_at == ~D[2024-04-15]
    end
  end

  describe "Delete" do
    test "success", %{conn: conn} do
      user = user_fixture()
      from_asset = asset_fixture(%{name: "SGD", user_id: user.id, root: true})
      to_asset = asset_fixture(%{name: "USD", user_id: user.id, root: false})

      {:ok, %{insert: trade}} =
        Trades.create(%{
          "from_asset_id" => from_asset.id,
          "from_qty" => 1,
          "to_asset_id" => to_asset.id,
          "to_qty" => 1,
          "user_id" => user.id,
          "to_asset_unit_cost" => 1,
          "transacted_at" => "2024-03-15"
        })

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/trades/new")

      assert lv |> element(~s{[phx-click="delete"]}) |> render_click() =~
               "Trade #{trade.id} Deleted"
    end
  end
end
