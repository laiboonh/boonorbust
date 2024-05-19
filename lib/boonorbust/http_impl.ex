defmodule Boonorbust.HttpImpl do
  @behaviour Boonorbust.HttpBehaviour

  @impl Boonorbust.HttpBehaviour
  def get(url) do
    Finch.build(:get, url)
    |> Finch.request(Boonorbust.Finch)
  end
end
