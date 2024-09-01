defmodule Boonorbust.HttpImpl do
  @behaviour Boonorbust.HttpBehaviour

  @impl Boonorbust.HttpBehaviour
  def get(url, headers \\ []) do
    Finch.build(:get, url, headers)
    |> Finch.request(Boonorbust.Finch)
  end
end
