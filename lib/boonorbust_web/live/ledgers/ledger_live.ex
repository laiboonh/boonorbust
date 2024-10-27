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
      <%= for {from_asset_name, %{trades: trades, total_qty: total_qty, total_cost: total_cost}} <- @ledgers.trades_by_from_asset_code do %>
        <%= from_asset_name %> Total Qty: <%= total_qty %> Total Cost: <%= total_cost %>
        <.table id="trades" rows={trades}>
          <:col :let={trade} label="Id"><%= trade.id %></:col>
          <:col :let={trade} label="<strong>From Qty (Trade)</strong>">
            <%= trade.from_qty %>
          </:col>
          <:col :let={trade} label="<strong>To Qty (Trade)</strong>">
            <%= trade.to_qty %>
          </:col>
          <:col :let={trade} label="Transacted At"><%= trade.transacted_at %></:col>
          <:col :let={trade} label="To Asset Unit Cost"><%= trade.to_asset_unit_cost %></:col>
        </.table>
      <% end %>
      Grand Total Cost In Local Currency: <%= @ledgers.grand_total_cost %><br />
      Grand Total Qty: <%= @ledgers.grand_total_qty %><br />
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
