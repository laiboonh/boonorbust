defmodule BoonorbustWeb.Trades.TradeLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Trades
  alias Boonorbust.Trades.Trade

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Trades
      <:subtitle><%= @action |> String.capitalize() %></:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form for={@trade_form} id="trade_form" phx-submit={@action}>
          <.input
            field={@trade_form[:from_asset_id]}
            label="From Asset"
            type="select"
            options={@asset_options}
            required
          />
          <.input
            field={@trade_form[:from_qty]}
            label="From Quantity"
            type="number"
            step="0.00001"
            required
          />
          <.input
            field={@trade_form[:to_asset_id]}
            label="To Asset"
            type="select"
            options={@asset_options}
            required
          />
          <.input
            field={@trade_form[:to_qty]}
            label="To Quantity"
            type="number"
            step="0.00001"
            required
          />
          <.input field={@trade_form[:user_id]} label="User ID" required readonly />
          <.input
            field={@trade_form[:to_asset_unit_cost]}
            label="To Asset Unit Cost"
            type="number"
            step="0.00001"
            required
          />
          <.input field={@trade_form[:transacted_at]} label="Transacted At" type="date" required />
          <:actions>
            <.button phx-disable-with="..."><%= @action |> String.capitalize() %></.button>
          </:actions>
        </.simple_form>
      </div>
    </div>

    <%= if @trades != nil do %>
      <.table id="trades" rows={@trades}>
        <:col :let={trade} label="Id"><%= trade.id %></:col>
        <:col :let={trade} label="From Asset">
          <%= asset_name(@asset_options, trade.from_asset_id) %>
        </:col>
        <:col :let={trade} label="From Quantity"><%= trade.from_qty %></:col>
        <:col :let={trade} label="To Asset">
          <%= asset_name(@asset_options, trade.to_asset_id) %>
        </:col>
        <:col :let={trade} label="To Quantity"><%= trade.to_qty %></:col>
        <:col :let={trade} label="To Asset Unit Cost"><%= trade.to_asset_unit_cost %></:col>
        <:col :let={trade} label="Transacted At"><%= trade.transacted_at %></:col>
        <:col :let={trade} label="Action">
          <.link patch={~p"/trades/#{trade.id}"}><.icon name="hero-pencil-square-solid" /></.link>
          <.link patch={~p"/trades/new"}><.icon name="hero-document-plus-solid" /></.link>
          <span phx-click="delete" phx-value-id={trade.id}><.icon name="hero-trash-solid" /></span>
        </:col>
      </.table>
    <% end %>
    """
  end

  def asset_name(asset_options, id) do
    {asset_name, _} =
      asset_options |> Enum.find(fn {_asset_name, asset_id} -> asset_id == id end)

    asset_name
  end

  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Trades.get(id, user_id) do
        nil ->
          trade_changeset = Trade.changeset(%Trade{}, %{})

          socket
          |> assign(:trades, Trades.all(user_id))
          |> assign(:action, "update")
          |> assign(:trade_form, to_form(trade_changeset))
          |> put_flash(:error, "Trade #{id} not found")

        trade ->
          trade_changeset = Trade.changeset(trade, %{})

          asset_options =
            Boonorbust.Assets.all(user_id) |> Enum.map(fn asset -> {asset.name, asset.id} end)

          socket
          |> assign(:trades, Trades.all(user_id))
          |> assign(:action, "update")
          |> assign(:trade_form, to_form(trade_changeset))
          |> assign(:asset_options, asset_options)
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    trade_changeset = Trade.changeset(%Trade{}, %{user_id: user_id})

    asset_options =
      Boonorbust.Assets.all(user_id) |> Enum.map(fn asset -> {asset.name, asset.id} end)

    socket =
      socket
      |> assign(:trades, Trades.all(user_id))
      |> assign(:action, "insert")
      |> assign(:trade_form, to_form(trade_changeset))
      |> assign(:asset_options, asset_options)

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    user_id = socket.assigns.current_user.id
    trade = Trades.get(id, user_id)
    trade_changeset = Trade.changeset(trade, %{})

    socket =
      socket
      |> assign(:trades, Trades.all(user_id))
      |> assign(:action, "update")
      |> assign(:trade_form, to_form(trade_changeset))

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:action, "insert")
      |> assign(:trade_form, to_form(Trade.changeset(%Trade{}, %{user_id: user.id})))

    {:noreply, socket}
  end

  def handle_event("insert", params, socket) do
    %{
      "trade" => %{
        "from_asset_id" => from_asset_id,
        "from_qty" => from_qty,
        "to_asset_id" => to_asset_id,
        "to_qty" => to_qty,
        "user_id" => user_id,
        "to_asset_unit_cost" => to_asset_unit_cost,
        "transacted_at" => transacted_at
      }
    } = params

    socket =
      case Trades.create(%{
             from_asset_id: from_asset_id,
             from_qty: from_qty,
             to_asset_id: to_asset_id,
             to_qty: to_qty,
             user_id: user_id,
             to_asset_unit_cost: to_asset_unit_cost,
             transacted_at: transacted_at
           }) do
        {:ok, trade} ->
          socket
          |> assign(:trades, Trades.all(user_id))
          |> assign(:trade_form, to_form(Trade.changeset(%Trade{}, %{user_id: user_id})))
          |> put_flash(:info, "Trade #{trade.id} Inserted")

        {:error, changeset} ->
          socket
          |> assign(:trade_form, to_form(Map.put(changeset, :action, :insert)))
          |> put_flash(:error, "Trade Insertion Failed")
      end

    {:noreply, socket}
  end

  def handle_event("update", params, socket) do
    %{hidden: [id: id]} = socket.assigns.trade_form

    %{
      "trade" => %{
        "from_asset_id" => from_asset_id,
        "from_qty" => from_qty,
        "to_asset_id" => to_asset_id,
        "to_qty" => to_qty,
        "user_id" => user_id,
        "to_asset_unit_cost" => to_asset_unit_cost,
        "transacted_at" => transacted_at
      }
    } = params

    socket =
      case Trades.update(id, user_id, %{
             from_asset_id: from_asset_id,
             from_qty: from_qty,
             to_asset_id: to_asset_id,
             to_qty: to_qty,
             user_id: user_id,
             to_asset_unit_cost: to_asset_unit_cost,
             transacted_at: transacted_at
           }) do
        {:ok, trade} ->
          info = "Trade #{trade.id} Updated"

          socket
          |> assign(:trades, Trades.all(user_id))
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :trade_form, to_form(Map.put(changeset, :action, :update)))
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Trades.delete(id, user_id) do
        {:ok, trade} ->
          info = "Trade #{trade.id} Deleted"

          socket
          |> assign(:trades, Trades.all(user_id))
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :trade_form, to_form(Map.put(changeset, :action, :delete)))
      end

    {:noreply, socket}
  end
end
