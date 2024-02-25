defmodule BoonorbustWeb.Assets.AssetLiveTest do
  use BoonorbustWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Boonorbust.AccountsFixtures

  describe "Create" do
    test "renders errors for creating assets with same name (case insensitive)", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/assets/new")

      result =
        lv
        |> form("#asset_form",
          asset: %{"name" => "foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "Asset foo Created"

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/assets/new")

      result =
        lv
        |> form("#asset_form",
          asset: %{"name" => "Foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end
end
