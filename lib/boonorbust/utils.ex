defmodule Boonorbust.Utils do
  @spec divide(Decimal.t(), Decimal.t()) :: Decimal.t()
  def divide(one, two) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 5})
    one |> Decimal.div(two)
  end

  def empty_string?(input), do: input == nil || input |> String.trim() == ""
end
