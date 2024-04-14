defmodule Boonorbust.AssetsTest do
  use Boonorbust.DataCase
  alias Boonorbust.Assets
  alias Boonorbust.Tags

  import Boonorbust.AccountsFixtures

  describe "create" do
    test "creating assets with associated tags" do
      user = user_fixture()

      assert {:ok, tag_1} = Tags.create(%{name: "tag_1", user_id: user.id})

      assert {:ok, asset} =
               Assets.create(%{
                 name: "foo",
                 user_id: user.id,
                 tag_ids: [tag_1.id]
               })

      assert asset.tags == [tag_1]
    end

    test "creating assets of the same name (case insensitive) returns error" do
      user = user_fixture()

      assert {:ok, _asset} = Assets.create(%{name: "foo", user_id: user.id})
      assert {:error, _asset} = Assets.create(%{name: "Foo", user_id: user.id})
    end
  end
end
