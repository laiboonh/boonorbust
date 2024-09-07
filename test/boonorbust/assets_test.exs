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
                 code: "GOOG",
                 type: :stock,
                 user_id: user.id,
                 tag_ids: [tag_1.id]
               })

      assert asset.tags == [tag_1]
    end

    test "creating assets of the same code (case insensitive) and type returns error" do
      user = user_fixture()

      assert {:ok, _asset} =
               Assets.create(%{name: "Foo", code: "APPL", type: :stock, user_id: user.id})

      assert {:ok, _asset} =
               Assets.create(%{name: "Foo", code: "APPL", type: :commodity, user_id: user.id})

      assert {:error, _asset} =
               Assets.create(%{name: "Foo", code: "appl", type: :stock, user_id: user.id})
    end
  end

  describe "all" do
    test "success" do
      user = user_fixture()

      assert {:ok, foo} =
               Assets.create(%{name: "foo", code: "GOOG", type: :stock, user_id: user.id})

      assert {:ok, bar} =
               Assets.create(%{name: "bar", code: "AAPL", type: :stock, user_id: user.id})

      assert Assets.all(user.id) == [bar, foo]

      assert Assets.all(user.id, order_by: :name, order: :desc) == [foo, bar]
    end
  end
end
