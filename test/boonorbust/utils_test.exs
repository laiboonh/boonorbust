defmodule Boonorbust.UtilsTest do
  use Boonorbust.DataCase
  alias Boonorbust.Utils

  describe "divide" do
    test "success" do
      assert Utils.divide(Decimal.new("100"), Decimal.new("3")) == Decimal.new("33.33333")
    end
  end

  describe "empty_string?" do
    test "success" do
      assert Utils.empty_string?("") == true
      assert Utils.empty_string?(nil) == true
      assert Utils.empty_string?(" ") == true
      assert Utils.empty_string?("foo") == false
    end
  end

  describe "month_as_integer" do
    test "success" do
      assert ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
             |> Enum.map(&Utils.month_as_integer(&1)) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

      assert ["jan", "feb", "mar", "APR", "MAy", "Jun", "jUL", "aug", "SEp", "Oct", "Nov", "DEC"]
             |> Enum.map(&Utils.month_as_integer(&1)) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    end
  end

  describe "convert_to_date" do
    test "success" do
      assert Boonorbust.Utils.convert_to_date("27 May 2024") == ~D[2024-05-27]
    end
  end
end
