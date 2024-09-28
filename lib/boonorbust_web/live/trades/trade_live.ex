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
        <.simple_form for={@trade_form} id="trade_form" phx-submit={@action} phx-change="validate">
          <.error :if={@trade_form.errors != []}>
            <%= raw(prepare_error_message(@trade_form.errors)) %>
          </.error>

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
          <.input
            field={@trade_form[:to_asset_unit_cost]}
            label="To Asset Unit Cost"
            type="number"
            step="0.00001"
          />
          <.input field={@trade_form[:transacted_at]} label="Transacted At" type="date" required />
          <.input field={@trade_form[:note]} label="Note" />
          <%= if @action == "insert" do %>
            <.input
              field={@trade_form[:auto_create]}
              type="checkbox"
              label="Auto Create Local Currency to From Asset Trade"
            />
          <% end %>
          <:actions>
            <.button phx-disable-with="..."><%= @action |> String.capitalize() %></.button>
          </:actions>
        </.simple_form>
      </div>
    </div>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form for={@filter_form}>
          <.input
            phx-change="filter_changed"
            label="Filter"
            field={@filter_form[:filter]}
            phx-debounce="2000"
          />
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
          <.link patch={~p"/trades"}><.icon name="hero-document-plus-solid" /></.link>
          <span phx-click="delete" phx-value-id={trade.id}><.icon name="hero-trash-solid" /></span>
        </:action>
      </.table>
    <% end %>

    <div style="display: flex; flex-direction: row; padding: 2px;">
      <div>
        <%= if @page_number > 1 do %>
          <.link patch={~p"/trades?page=#{@page_number - 1}"}>
            <div class="flex gap-2 items-center ">
              Previous
            </div>
          </.link>
        <% end %>
      </div>

      <div style="display: flex; flex-direction: row; padding: 2px;">
        <%= for idx <-  Enum.to_list(1..@total_pages) do %>
          <.link patch={~p"/trades?filter=#{@filter}&page=#{idx}"}>
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
          <.link patch={~p"/trades?filter=#{@filter}&page=#{@page_number + 1}"}>
            <div class="flex gap-2 items-center ">
              Next
            </div>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    user_id = socket.assigns.current_user.id

    trade_changeset = Trade.changeset(%Trade{}, %{user_id: user_id})

    socket =
      socket
      |> refresh_table(params)
      |> assign(:action, "insert")
      |> assign(:trade_form, to_form(trade_changeset))
      # For `/trades?filter=ba&page=1` so that we keep `filter` value in filter_form
      |> assign(:filter_form, to_form(params))
      |> assign(:asset_options, asset_options(user_id))

    {:ok, socket}
  end

  def handle_params(%{"id" => id} = params, _uri, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Trades.get(id, user_id) do
        nil ->
          socket
          |> refresh_table(params)
          |> assign(:action, "update")
          |> flash(:error, "Trade #{id} not found")

        trade ->
          socket
          |> refresh_table(params)
          |> assign(:action, "update")
          |> assign(:trade_form, to_form(Trade.changeset(trade, %{})))
      end

    {:noreply, socket}
  end

  # For `/trades?page`=1 where there are params
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> refresh_table(params)
      |> assign(:action, "insert")
      |> assign(
        :trade_form,
        to_form(Trade.changeset(%Trade{}, %{transacted_at: Date.utc_today()}))
      )

    {:noreply, socket}
  end

  def handle_event("validate", %{"trade" => trade_params}, socket) do
    user_id = socket.assigns.current_user.id

    # we use assigns.trade_form.data because for edits, it will contain the id of the trade we are editing
    trade = socket.assigns.trade_form.data

    changeset = Trade.changeset(trade, trade_params |> Map.put("user_id", user_id))

    {:noreply, assign(socket, :trade_form, to_form(Map.put(changeset, :action, :validate)))}
  end

  def handle_event("insert", params, socket) do
    user_id = socket.assigns.current_user.id

    %{
      "trade" => %{
        "from_asset_id" => from_asset_id,
        "from_qty" => from_qty,
        "to_asset_id" => to_asset_id,
        "to_qty" => to_qty,
        "to_asset_unit_cost" => to_asset_unit_cost,
        "transacted_at" => transacted_at,
        "note" => note,
        "auto_create" => auto_create
      }
    } = params

    socket =
      case Trades.create(
             %{
               from_asset_id:
                 if !Boonorbust.Utils.empty_string?(from_asset_id) do
                   String.to_integer(from_asset_id)
                 end,
               from_qty: from_qty,
               to_asset_id:
                 if !Boonorbust.Utils.empty_string?(to_asset_id) do
                   String.to_integer(to_asset_id)
                 end,
               to_qty: to_qty,
               user_id: user_id,
               to_asset_unit_cost: to_asset_unit_cost,
               transacted_at: transacted_at,
               note: note
             },
             auto_create == "true"
           ) do
        {:ok, %{insert: trade}} ->
          socket
          |> refresh_table(params)
          |> assign(
            :trade_form,
            to_form(
              Trade.changeset(%Trade{}, %{user_id: user_id, transacted_at: Date.utc_today()})
            )
          )
          |> flash(:info, "Trade #{trade.id} Inserted. Ledger updated.")

        {:error, _failed_operation, changeset, _changes_so_far} ->
          socket
          |> assign(:trade_form, to_form(changeset))
          |> flash(:error, "Trade Insertion Failed")
      end

    {:noreply, socket}
  end

  def handle_event("update", params, socket) do
    trade_id = socket.assigns.trade_form.data.id
    user_id = socket.assigns.current_user.id

    %{
      "trade" => %{
        "from_asset_id" => from_asset_id,
        "from_qty" => from_qty,
        "to_asset_id" => to_asset_id,
        "to_qty" => to_qty,
        "to_asset_unit_cost" => to_asset_unit_cost,
        "transacted_at" => transacted_at,
        "note" => note
      }
    } = params

    socket =
      case Trades.update(trade_id, user_id, %{
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
          |> flash(:info, info)

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
          |> flash(:info, info)

        {:error, changeset} ->
          assign(socket, :trade_form, to_form(Map.put(changeset, :action, :delete)))
      end

    {:noreply, socket}
  end

  def handle_event("filter_changed", %{"filter" => filter}, socket) do
    {:noreply, refresh_table(socket, %{"filter" => filter})}
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
        |> Enum.map(fn asset ->
          if asset.type == :stock do
            {"#{asset.name} (#{asset.code})", asset.id}
          else
            {asset.name, asset.id}
          end
        end)
    ]
  end

  defp refresh_table(socket, params) do
    user_id = socket.assigns.current_user.id

    result =
      Trades.all(user_id, %{
        page: Map.get(params, "page", 1),
        page_size: Map.get(params, "page_size", @page_size),
        filter: Map.get(params, "filter")
      })

    socket
    |> assign(:trades, result.entries)
    |> assign(:total_pages, result.total_pages)
    |> assign(:page_number, result.page_number)
    |> assign(:total_entries, result.total_entries)
    |> assign(:filter, Map.get(params, "filter", ""))
  end

  defp prepare_error_message(errors) do
    Enum.map_join(errors, "<br/>", fn {_, {message, _}} -> message end)
  end

  defp flash(socket, key, message) do
    clear_flash(socket)
    |> put_flash(key, message)
  end
end
