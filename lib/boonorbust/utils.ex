defmodule Boonorbust.Utils do
  @spec divide(Decimal.t(), Decimal.t()) :: Decimal.t()
  def divide(one, two) do
    Decimal.Context.set(%Decimal.Context{Decimal.Context.get() | precision: 5})
    one |> Decimal.div(two)
  end

  @spec empty_string?(String.t()) :: boolean()
  def empty_string?(input), do: input == nil || input |> String.trim() == ""

  @spec month_as_integer(String.t()) :: integer()
  # credo:disable-for-next-line
  def month_as_integer(input) do
    case input do
      "Jan" -> 1
      "Feb" -> 2
      "Mar" -> 3
      "Apr" -> 4
      "May" -> 5
      "Jun" -> 6
      "Jul" -> 7
      "Aug" -> 8
      "Sep" -> 9
      "Oct" -> 10
      "Nov" -> 11
      "Dec" -> 12
    end
  end

  def convert_to_date(input) do
    [day, month, year] = input |> String.split()
    month = month_as_integer(month)
    Date.from_erl!({year |> String.to_integer(), month, day |> String.to_integer()})
  end
end
