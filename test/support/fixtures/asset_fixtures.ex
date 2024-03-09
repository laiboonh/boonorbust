defmodule Boonorbust.AssetsFixtures do
  def asset_fixture(attrs \\ %{}) do
    {:ok, asset} = Boonorbust.Assets.create(attrs)
    asset
  end
end
