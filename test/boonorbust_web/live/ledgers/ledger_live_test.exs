defmodule BoonorbustWeb.Ledgers.LedgerLiveTest do
  use BoonorbustWeb.ConnCase, async: true

  # import Phoenix.LiveViewTest
  import Boonorbust.AccountsFixtures

  alias Boonorbust.Assets
  alias Boonorbust.Trades

  describe "Search" do
    test "success", %{conn: _conn} do
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

      {:ok, _result} =
        Trades.create(%{
          from_asset_id: sgd.id,
          to_asset_id: usd.id,
          from_qty: 105,
          to_qty: 75,
          to_asset_unit_cost: 1.4,
          transacted_at: Date.utc_today(),
          user_id: user.id
        })

      # {:ok, lv, html} = conn |> log_in_user(user) |> live(~p"/ledgers")

      # rows =
      #   Floki.parse_document!(html)
      #   |> Floki.find("#ledgers > tr")

      # inventory qty
      # assert rows |> find_in_table(1, 8) =~ "-105"

      # # inventory cost
      # assert rows |> find_in_table(1, 10) =~ "105"

      # # weighted average cost
      # assert rows |> find_in_table(1, 9) =~ "1"

      # rows =
      #   lv
      #   |> element("form")
      #   |> render_change(%{asset_id: usd.id})
      #   |> Floki.parse_document!()
      #   |> Floki.find("#ledgers > tr")

      # # inventory qty
      # assert rows |> find_in_table(1, 8) =~ "75"

      # # inventory cost
      # assert rows |> find_in_table(1, 10) =~ "105"

      # # weighted average cost
      # assert rows |> find_in_table(1, 9) =~ "1.4"
    end
  end

  # defp find_in_table(rows, row_num, col_num) do
  #   rows
  #   |> Enum.at(row_num - 1)
  #   |> Floki.children()
  #   |> Enum.at(col_num - 1)
  #   |> Floki.text()
  # end
end
