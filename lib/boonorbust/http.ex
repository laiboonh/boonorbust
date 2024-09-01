defmodule Boonorbust.Http do
  def get(url, headers \\ []) do
    http_impl().get(url, headers)
  end

  defp http_impl do
    Application.get_env(:boonorbust, :http, Boonorbust.HttpImpl)
  end
end
