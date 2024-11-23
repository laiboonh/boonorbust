defmodule Boonorbust.ExchangeRatesTest do
  use Boonorbust.DataCase

  import Mox
  setup :verify_on_exit!

  describe "convert" do
    test "success" do
      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: """
           {
           "data": {
            "2019-05-19": {
                "THB": 23.126908
              }
            }
           }
           """
         }}
      end)

      assert Boonorbust.ExchangeRates.convert("SGD", "THB", ~D[2019-05-19], Decimal.new("100")) ==
               %{rate_used: Decimal.new("23.126908"), to_amount: Decimal.new("2312.690800")}

      # EXtra calls won't trigger another api call
      assert Boonorbust.ExchangeRates.convert("SGD", "THB", ~D[2019-05-19], Decimal.new("100")) ==
               %{rate_used: Decimal.new("23.126908"), to_amount: Decimal.new("2312.690800")}
    end
  end
end
