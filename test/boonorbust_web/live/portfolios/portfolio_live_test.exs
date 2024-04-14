defmodule BoonorbustWeb.Portfolios.PortfolioLiveTest do
  alias Boonorbust.Portfolios
  use BoonorbustWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Boonorbust.AccountsFixtures

  describe "Insert" do
    test "renders errors for creating portfolios with same name (case insensitive)", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/portfolios/new")

      result =
        lv
        |> form("#portfolio_form",
          portfolio: %{"name" => "foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "Portfolio foo Inserted"

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/portfolios/new")

      result =
        lv
        |> form("#portfolio_form",
          portfolio: %{"name" => "Foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "Update" do
    test "renders errors for creating portfolios with same name (case insensitive)", %{conn: conn} do
      user = user_fixture()
      {:ok, _portfolio} = Portfolios.create(%{name: "foo", user_id: user.id})
      {:ok, portfolio} = Portfolios.create(%{name: "bar", user_id: user.id})

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/portfolios/#{portfolio.id}")

      result =
        lv
        |> form("#portfolio_form",
          portfolio: %{"name" => "Foo"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "Delete" do
    test "success", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/portfolios/new")

      result =
        lv
        |> form("#portfolio_form",
          portfolio: %{"name" => "foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "Portfolio foo Inserted"

      assert lv |> element(~s{[phx-click="delete"]}) |> render_click() =~ "Portfolio foo Deleted"
    end
  end
end
