defmodule Boonorbust.Utils do
  @spec divide(Decimal.t(), Decimal.t()) :: Decimal.t()
  def divide(one, two) do
    one |> Decimal.div(two) |> Decimal.round(5)
  end

  @spec empty_string?(String.t()) :: boolean()
  def empty_string?(input), do: input == nil || input |> String.trim() == ""

  @spec month_as_integer(String.t()) :: integer()
  # credo:disable-for-next-line
  def month_as_integer(input) do
    case input |> String.upcase() do
      "JAN" -> 1
      "FEB" -> 2
      "MAR" -> 3
      "APR" -> 4
      "MAY" -> 5
      "JUN" -> 6
      "JUL" -> 7
      "AUG" -> 8
      "SEP" -> 9
      "OCT" -> 10
      "NOV" -> 11
      "DEC" -> 12
    end
  end

  @spec convert_to_date(String.t()) :: Date.t()
  def convert_to_date(input) do
    [day, month, year] = input |> String.split()
    month = month_as_integer(month)
    Date.from_erl!({year |> String.to_integer(), month, day |> String.to_integer()})
  end
end
