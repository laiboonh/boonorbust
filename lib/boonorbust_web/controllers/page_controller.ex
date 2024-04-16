defmodule BoonorbustWeb.PageController do
  alias Boonorbust.Ledgers
  use BoonorbustWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)

    case Map.get(conn.assigns, :current_user) do
      nil ->
        render(conn, :home, latest_ledgers: nil, profit_percent: nil, portfolios: nil)

      current_user ->
        all_latest =
          Ledgers.all_latest(current_user.id) |> Enum.sort_by(& &1.profit_percent, :desc)

        render(conn, :home,
          latest_ledgers: all_latest,
          profit_percent: Ledgers.profit_percent(current_user.id, all_latest),
          portfolios: Ledgers.portfolios(current_user.id, all_latest)
        )
    end
  end
end
