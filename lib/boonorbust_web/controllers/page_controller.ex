defmodule BoonorbustWeb.PageController do
  alias Boonorbust.Ledgers
  use BoonorbustWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)

    case Map.get(conn.assigns, :current_user) do
      nil ->
        render(conn, :home, latest_ledgers: nil)

      current_user ->
        latest_ledgers =
          Ledgers.all_latest(current_user.id)
          |> Enum.map(fn ledger ->
            Map.put(ledger, :latest_price, latest_price(ledger.asset.code))
          end)

        render(conn, :home, latest_ledgers: latest_ledgers)
    end
  end

  def latest_price("FUND." <> code) do
    {:ok, %Finch.Response{body: body}} =
      Finch.build(:get, "https://markets.ft.com/data/funds/tearsheet/summary?s=#{code}:SGD")
      |> Finch.request(Boonorbust.Finch)

    Floki.parse_document!(body)
    |> Floki.find(".mod-ui-data-list__value")
    |> hd()
    |> Floki.text()
  end

  def latest_price(_code), do: "1"
end
