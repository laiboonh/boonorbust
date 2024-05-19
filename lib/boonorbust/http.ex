defmodule Boonorbust.Http do
  def get(url) do
    http_impl().get(url)
  end

  defp http_impl do
    Application.get_env(:boonorbust, :http, Boonorbust.HttpImpl)
  end
end
