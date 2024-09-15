defmodule BoonorbustWeb.Tags.TagLiveTest do
  alias Boonorbust.Tags
  use BoonorbustWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Boonorbust.AccountsFixtures

  describe "Insert" do
    test "renders errors for creating tags with same name (case insensitive)", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/tags")

      result =
        lv
        |> form("#tag_form",
          tag: %{"name" => "foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "Tag foo Inserted"

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/tags")

      result =
        lv
        |> form("#tag_form",
          tag: %{"name" => "Foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "Update" do
    test "renders errors for creating tags with same name (case insensitive)", %{conn: conn} do
      user = user_fixture()
      {:ok, _tag} = Tags.create(%{name: "foo", user_id: user.id})
      {:ok, tag} = Tags.create(%{name: "bar", user_id: user.id})

      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/tags/#{tag.id}")

      result =
        lv
        |> form("#tag_form",
          tag: %{"name" => "Foo"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "Delete" do
    test "success", %{conn: conn} do
      user = user_fixture()
      {:ok, lv, _html} = conn |> log_in_user(user) |> live(~p"/tags")

      result =
        lv
        |> form("#tag_form",
          tag: %{"name" => "foo", "user_id" => user.id}
        )
        |> render_submit()

      assert result =~ "Tag foo Inserted"

      assert lv |> element(~s{[phx-click="delete"]}) |> render_click() =~ "Tag foo Deleted"
    end
  end
end
