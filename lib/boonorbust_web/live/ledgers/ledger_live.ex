defmodule BoonorbustWeb.Ledgers.LedgerLive do
  alias Boonorbust.Ledgers
  use BoonorbustWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Ledgers <span phx-click="recalculate"><.icon name="hero-calculator-solid" /></span>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form for={@ledger_form} id="ledger_form" phx-change={@action}>
          <.input
            field={@ledger_form[:asset_id]}
            label="Asset"
            type="select"
            options={@asset_options}
            required
          />
        </.simple_form>
      </div>
    </div>

    <%= if @ledgers != nil do %>
      <.table id="ledgers" rows={@ledgers}>
        <:col :let={ledger} label="Id"><%= ledger.id %></:col>
        <:col :let={ledger} label="<strong>From Qty (Trade)</strong>">
          <%= ledger.trade.from_qty %> <%= ledger.trade.from_asset.code %>
        </:col>
        <:col :let={ledger} label="<strong>To Qty (Trade)</strong>">
          <%= ledger.trade.to_qty %> <%= ledger.trade.to_asset.code %>
        </:col>
        <:col :let={ledger} label="Transacted At"><%= ledger.transacted_at %></:col>
        <:col :let={ledger} label="Qty"><%= ledger.qty %></:col>
        <:col :let={ledger} label="Unit Cost"><%= ledger.unit_cost %></:col>
        <:col :let={ledger} label="Total Cost"><%= ledger.total_cost %></:col>
        <:col :let={ledger} label="Inventory Qty"><%= ledger.inventory_qty %></:col>
        <:col :let={ledger} label="Weighted Avg Cost"><%= ledger.weighted_average_cost %></:col>
        <:col :let={ledger} label="Inventory Cost"><%= ledger.inventory_cost %></:col>
      </.table>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    asset_options =
      Boonorbust.Assets.all(user_id, order_by: :name, order: :asc)
      |> Enum.map(fn asset -> {asset.name, asset.id} end)

    {_asset_name, asset_id} = asset_options |> List.first()

    socket =
      socket
      |> assign(:ledgers, Ledgers.all(user_id, asset_id))
      |> assign(:asset_options, asset_options)
      |> assign(:ledger_form, to_form(%{"asset_id" => asset_id}))
      |> assign(:action, "search")

    {:ok, socket}
  end

  def handle_event("search", %{"asset_id" => asset_id}, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(:ledgers, Ledgers.all(user_id, asset_id))
      |> assign(:action, "search")

    {:noreply, socket}
  end

  def handle_event("recalculate", _params, socket) do
    user_id = socket.assigns.current_user.id
    :ok = Ledgers.recalculate(user_id)

    socket =
      socket
      |> assign(:ledgers, Ledgers.all(user_id, socket.assigns.ledger_form.params["asset_id"]))

    {:noreply, socket}
  end
end
