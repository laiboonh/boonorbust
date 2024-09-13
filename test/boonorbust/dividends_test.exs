defmodule Boonorbust.DividendsTest do
  use Boonorbust.DataCase

  import Boonorbust.AccountsFixtures
  import Mox
  setup :verify_on_exit!

  alias Boonorbust.Assets

  describe "upsert_dividend_declarations" do
    test "success" do
      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             Path.join([File.cwd!(), "test", "boonorbust", "dividends", "etnet_success.html"])
             |> File.read!()
         }}
      end)

      user = user_fixture()

      assert {:ok, asset} =
               Assets.create(%{
                 name: "BABA",
                 code: "HKEX:9988",
                 type: :stock,
                 user_id: user.id
               })

      assert Boonorbust.Dividends.upsert_dividend_declarations(asset) == {3, nil}

      assert Boonorbust.Dividends.all(asset) |> length == 3
    end
  end
end
