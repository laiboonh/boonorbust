defmodule Boonorbust.HttpBehaviour do
  @callback get(binary()) :: {:ok, struct()} | {:error, Exception.t()}
end
