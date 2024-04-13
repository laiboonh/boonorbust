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
        render(conn, :home, latest_ledgers: Ledgers.all_latest(current_user.id))
    end
  end
end
