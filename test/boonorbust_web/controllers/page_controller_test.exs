defmodule BoonorbustWeb.PageControllerTest do
  use BoonorbustWeb.ConnCase, async: true

  import Boonorbust.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  test "GET / with a logged in user", %{conn: conn, user: user} do
    conn =
      post(conn, ~p"/users/log_in", %{
        "user" => %{"email" => user.email, "password" => valid_user_password()}
      })

    assert get_session(conn, :user_token)
    assert redirected_to(conn) == ~p"/"

    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    assert response =~ "Latest Price"
  end
end
