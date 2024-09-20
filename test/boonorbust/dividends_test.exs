defmodule Boonorbust.DividendsTest do
  use Boonorbust.DataCase

  import Boonorbust.AccountsFixtures
  import Mox
  setup :verify_on_exit!

  alias Boonorbust.Assets

  describe "upsert_dividend_declarations" do
    test "success for HKEX asset" do
      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             Path.join([File.cwd!(), "test", "boonorbust", "dividends", "etnet_success.html"])
             |> File.read!()
         }}
      end)

      user = user_fixture()

      assert {:ok, asset} =
               Assets.create(%{
                 name: "BABA",
                 code: "HKEX:9988",
                 type: :stock,
                 user_id: user.id
               })

      assert Boonorbust.Dividends.upsert_dividend_declarations(asset) == {3, nil}

      assert Boonorbust.Dividends.all_declarations(asset) |> length == 3

      assert Boonorbust.Dividends.find_declarations(asset.id, ~D[2024-06-12]) |> length == 2
    end

    test "success for NASDAQ, NYSE asset" do
      expect(HttpBehaviourMock, :get, fn _url, _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             Path.join([File.cwd!(), "test", "boonorbust", "dividends", "fmp_success.json"])
             |> File.read!()
         }}
      end)

      user = user_fixture()

      assert {:ok, asset} =
               Assets.create(%{
                 name: "APPLE",
                 code: "NASDAQ:AAPL",
                 type: :stock,
                 user_id: user.id
               })

      assert Boonorbust.Dividends.upsert_dividend_declarations(asset) == {83, nil}

      assert Boonorbust.Dividends.all_declarations(asset) |> length == 83

      assert Boonorbust.Dividends.find_declarations(asset.id, ~D[2024-08-12]) |> length == 1
    end

    test "success for SGX asset" do
      expect(HttpBehaviourMock, :get, fn "https://www.dividends.sg/view/Y92", _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             Path.join([
               File.cwd!(),
               "test",
               "boonorbust",
               "dividends",
               "dividends_sg_success.html"
             ])
             |> File.read!()
         }}
      end)

      expect(HttpBehaviourMock, :get, fn "https://links.sgx.com/1.0.0/corporate-actions/1637953",
                                         _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             Path.join([
               File.cwd!(),
               "test",
               "boonorbust",
               "dividends",
               "sgx_1637953_success.html"
             ])
             |> File.read!()
         }}
      end)

      expect(HttpBehaviourMock, :get, fn "https://links.sgx.com/1.0.0/corporate-actions/1544432",
                                         _headers ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             Path.join([
               File.cwd!(),
               "test",
               "boonorbust",
               "dividends",
               "sgx_1544432_success.html"
             ])
             |> File.read!()
         }}
      end)

      user = user_fixture()

      assert {:ok, asset} =
               Assets.create(%{
                 name: "Y92",
                 code: "SGX:Y92",
                 type: :stock,
                 user_id: user.id
               })

      assert Boonorbust.Dividends.upsert_dividend_declarations(asset) == {2, nil}

      assert Boonorbust.Dividends.all_declarations(asset) |> length == 2

      assert Boonorbust.Dividends.find_declarations(asset.id, ~D[2024-02-06]) |> length == 1
    end
  end
end
