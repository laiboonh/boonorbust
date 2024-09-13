defmodule Boonorbust.ExchangeRatesTest do
  use Boonorbust.DataCase

  import Mox
  setup :verify_on_exit!

  describe "get_exchange_rate" do
    test "success" do
      # API only called once
      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: """
           {
           "success": true,
           "timestamp": 1558310399,
           "historical": true,
           "base": "SGD",
           "date": "2019-05-19",
           "rates": {
           "THB": 23.126908
           }
           }
           """
         }}
      end)

      assert Boonorbust.ExchangeRates.get_exchange_rate("SGD", "THB", ~D[2019-05-19]) ==
               Decimal.new("23.126908")

      assert Boonorbust.ExchangeRates.get_exchange_rate("SGD", "THB", ~D[2019-05-19]) ==
               Decimal.new("23.126908")
    end
  end

  describe "convert" do
    test "success" do
      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body: """
           {
           "success": true,
           "timestamp": 1558310399,
           "historical": true,
           "base": "SGD",
           "date": "2019-05-19",
           "rates": {
           "THB": 23.126908
           }
           }
           """
         }}
      end)

      assert Boonorbust.ExchangeRates.convert("SGD", "THB", ~D[2019-05-19], Decimal.new("100")) ==
               %{rate_used: Decimal.new("23.126908"), to_amount: Decimal.new("2312.690800")}
    end
  end
end
