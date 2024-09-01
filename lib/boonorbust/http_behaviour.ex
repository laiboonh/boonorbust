defmodule Boonorbust.HttpBehaviour do
  @callback get(binary(), list({String.t(), String.t()})) ::
              {:ok, struct()} | {:error, Exception.t()}
end
