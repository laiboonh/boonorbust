defmodule BoonorbustWeb.Trades.TradeLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Trades
  alias Boonorbust.Trades.Trade

  @page_size 20

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
          />
          <.input field={@trade_form[:from_qty]} label="From Quantity" type="number" step="0.00001" />
          <.input
            field={@trade_form[:to_asset_id]}
            label="To Asset"
            type="select"
            options={@asset_options}
          />
          <.input field={@trade_form[:to_qty]} label="To Quantity" type="number" step="0.00001" />
          <.input field={@trade_form[:user_id]} label="User ID" required readonly />
          <.input
            field={@trade_form[:to_asset_unit_cost]}
            label="To Asset Unit Cost"
            type="number"
            step="0.00001"
          />
          <.input field={@trade_form[:transacted_at]} label="Transacted At" type="date" required />
          <.input field={@trade_form[:note]} label="Note" />
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
        <:col :let={trade} label="Note"><%= trade.note %></:col>
        <:action :let={trade}>
          <.link patch={~p"/trades/#{trade.id}"}><.icon name="hero-pencil-square-solid" /></.link>
          <.link patch={~p"/trades/new"}><.icon name="hero-document-plus-solid" /></.link>
          <span phx-click="delete" phx-value-id={trade.id}><.icon name="hero-trash-solid" /></span>
        </:action>
      </.table>
    <% end %>

    <div style="display: flex; flex-direction: row; padding: 2px;">
      <div>
        <%= if @page_number > 1 do %>
          <.link patch={~p"/trades/new?page=#{@page_number - 1}"}>
            <div class="flex gap-2 items-center ">
              Previous
            </div>
          </.link>
        <% end %>
      </div>

      <div style="display: flex; flex-direction: row; padding: 2px;">
        <%= for idx <-  Enum.to_list(1..@total_pages) do %>
          <.link patch={~p"/trades/new?page=#{idx}"}>
            <%= if @page_number == idx do %>
              <p style="border: 1px solid black; padding-left: 5px; padding-right: 5px;">
                <%= idx %>
              </p>
            <% else %>
              <p style="padding-left: 5px; padding-right: 5px;">
                <%= idx %>
              </p>
            <% end %>
          </.link>
        <% end %>
      </div>

      <div>
        <%= if @page_number < @total_pages do %>
          <.link patch={~p"/trades/new?page=#{@page_number + 1}"}>
            <div class="flex gap-2 items-center ">
              Next
            </div>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  defp asset_name(asset_options, id) do
    {asset_name, _} =
      asset_options |> Enum.find(fn {_asset_name, asset_id} -> asset_id == id end)

    asset_name
  end

  defp asset_options(user_id) do
    [
      {"-", nil}
      | Boonorbust.Assets.all(user_id, order_by: :name, order: :asc)
        |> Enum.map(fn asset -> {asset.name, asset.id} end)
    ]
  end

  def refresh_table(socket, params) do
    user_id = socket.assigns.current_user.id

    result =
      Trades.all(user_id, %{
        page: Map.get(params, "page", 1),
        page_size: Map.get(params, "page_size", @page_size)
      })

    socket
    |> assign(:trades, result.entries)
    |> assign(:total_pages, result.total_pages)
    |> assign(:page_number, result.page_number)
    |> assign(:total_entries, result.total_entries)
  end

  def mount(%{"id" => id} = params, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Trades.get(id, user_id) do
        nil ->
          trade_changeset = Trade.changeset(%Trade{}, %{})

          socket
          |> refresh_table(params)
          |> assign(:action, "update")
          |> assign(:trade_form, to_form(trade_changeset))
          |> put_flash(:error, "Trade #{id} not found")

        trade ->
          trade_changeset = Trade.changeset(trade, %{})

          socket
          |> refresh_table(params)
          |> assign(:action, "update")
          |> assign(:trade_form, to_form(trade_changeset))
          |> assign(:asset_options, asset_options(user_id))
      end

    {:ok, socket}
  end

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_user.id

    trade_changeset = Trade.changeset(%Trade{}, %{user_id: user_id})

    socket =
      socket
      |> refresh_table(params)
      |> assign(:action, "insert")
      |> assign(:trade_form, to_form(trade_changeset))
      |> assign(:asset_options, asset_options(user_id))

    {:ok, socket}
  end

  def handle_params(%{"id" => id} = params, _uri, socket) do
    user_id = socket.assigns.current_user.id
    trade = Trades.get(id, user_id)
    trade_changeset = Trade.changeset(trade, %{})

    socket =
      socket
      |> refresh_table(params)
      |> assign(:action, "update")
      |> assign(:trade_form, to_form(trade_changeset))

    {:noreply, socket}
  end

  def handle_params(params, _uri, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> refresh_table(params)
      |> assign(:action, "insert")
      |> assign(:trade_form, to_form(Trade.changeset(%Trade{}, %{user_id: user_id})))

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
        "transacted_at" => transacted_at,
        "note" => note
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
             transacted_at: transacted_at,
             note: note
           }) do
        {:ok, %{insert: trade}} ->
          socket
          |> refresh_table(params)
          |> assign(:trade_form, to_form(Trade.changeset(%Trade{}, %{user_id: user_id})))
          |> put_flash(:info, "Trade #{trade.id} Inserted. Ledger updated.")

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
        "transacted_at" => transacted_at,
        "note" => note
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
             transacted_at: transacted_at,
             note: note
           }) do
        {:ok, trade} ->
          info = "Trade #{trade.id} Updated"

          socket
          |> refresh_table(params)
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :trade_form, to_form(Map.put(changeset, :action, :update)))
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id} = params, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Trades.delete(id, user_id) do
        {:ok, trade} ->
          info = "Trade #{trade.id} Deleted"

          socket
          |> refresh_table(params)
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :trade_form, to_form(Map.put(changeset, :action, :delete)))
      end

    {:noreply, socket}
  end
end
