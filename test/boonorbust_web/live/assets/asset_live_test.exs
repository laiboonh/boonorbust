defmodule BoonorbustWeb.Assets.AssetLiveTest do
  alias Boonorbust.Assets
  use BoonorbustWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Boonorbust.AccountsFixtures

  describe "Insert" do
    test "renders errors for creating assets with same name (case insensitive)", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/assets/new")

      result =
        lv
        |> form("#asset_form",
          asset: %{"name" => "foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "Asset foo Inserted"

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

  describe "Update" do
    test "renders errors for creating assets with same name (case insensitive)", %{conn: conn} do
      user = user_fixture()
      {:ok, _asset} = Assets.create(%{name: "foo", user_id: user.id})
      {:ok, asset} = Assets.create(%{name: "bar", user_id: user.id})

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/assets/#{asset.id}")

      result =
        lv
        |> form("#asset_form",
          asset: %{"name" => "Foo"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "Delete" do
    test "success", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/assets/new")

      result =
        lv
        |> form("#asset_form",
          asset: %{"name" => "foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "Asset foo Inserted"

      assert lv |> element(~s{[phx-click="delete"]}) |> render_click() =~ "Asset foo Deleted"
    end
  end
end
