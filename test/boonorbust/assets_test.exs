defmodule Boonorbust.AssetsTest do
  use Boonorbust.DataCase
  alias Boonorbust.Assets

  import Boonorbust.AccountsFixtures

  describe "create" do
    test "creating assets of the same name (case insensitive) returns error" do
      user = user_fixture()
      assert {:ok, _asset} = Assets.create(%{name: "foo", user_id: user.id})
      assert {:error, _asset} = Assets.create(%{name: "Foo", user_id: user.id})
    end
  end
end
