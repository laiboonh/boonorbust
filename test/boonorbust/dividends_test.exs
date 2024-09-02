defmodule Boonorbust.DividendsTest do
  use Boonorbust.DataCase

  import Mox
  setup :verify_on_exit!

  describe "get_dividend_history" do
    test "success" do
      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             Path.join([File.cwd!(), "test", "boonorbust", "dividends", "etnet_success.html"])
             |> File.read!()
         }}
      end)

      assert Boonorbust.Dividends.get_dividend_history_hkex("9988") == [
               ["USD", 0.125, ~D[2023-12-20], ~D[2024-01-11]],
               ["USD", 0.0825, ~D[2024-06-12], ~D[2024-07-03]],
               ["USD", 0.125, ~D[2024-06-12], ~D[2024-07-03]]
             ]
    end
  end
end
