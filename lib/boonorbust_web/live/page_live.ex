defmodule BoonorbustWeb.PageLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Ledgers
  alias Boonorbust.Profits

  def render(assigns) do
    ~H"""
    <%= if @loading_all_assets do %>
      <.spinner text="Loading all assets..." />
    <% end %>

    <%= if @profit_percent do %>
      <%= if @profit_percent |> Decimal.positive?() do %>
        <p
          phx-click={show_modal("profit-svg-modal")}
          class="text-green-700 text-2xl underline decoration-double text-right"
        >
          <%= @profit_percent %>%
        </p>
      <% else %>
        <p
          phx-click={show_modal("profit-svg-modal")}
          class="text-red-700 text-2xl underline decoration-double text-right"
        >
          <%= @profit_percent %>%
        </p>
      <% end %>
    <% end %>

    <.modal id="profit-svg-modal">
      <%= if @profit_svg do %>
        <%= @profit_svg %>
      <% end %>
    </.modal>

    <%= if @portfolio_svgs do %>
      <%= for portfolio_svg <- @portfolio_svgs do %>
        <%= portfolio_svg %>
      <% end %>
    <% end %>

    <%= if @latest_ledgers do %>
      <.table id="ledgers" rows={@latest_ledgers |> Enum.reject(&(&1.asset.root == true))}>
        <:col :let={ledger} label="<span phx-click='sort' phx-value-sort_by='name'>Name</span>">
          <%= ledger.asset.name %><br />
          <p class="text-slate-400"><%= ledger.asset.code %></p>
        </:col>
        <:col
          :let={ledger}
          label="<span phx-click='sort' phx-value-sort_by='latest_proportion'>Latest Cost</span>"
        >
          <%= ledger.inventory_cost %>
        </:col>
        <:col
          :let={ledger}
          label="<span phx-click='sort' phx-value-sort_by='latest_proportion'>Latest Value</span>"
        >
          <%= ledger.latest_value %>
        </:col>
        <:col
          :let={ledger}
          label="<span phx-click='sort' phx-value-sort_by='profit_percent'>Profit %</span>"
        >
          <%= ledger.profit_percent %>%
        </:col>
        <:col
          :let={ledger}
          label="<span phx-click='sort' phx-value-sort_by='latest_proportion'>Proportion %</span>"
        >
          <%= ledger.latest_proportion %>%
        </:col>
      </.table>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    self = self()

    if connected?(socket) do
      user_id = socket.assigns.current_user.id

      {:ok, _pid} =
        Task.start_link(fn ->
          send(self, :working)
          all_latest = Ledgers.all_non_currency_latest(user_id)
          send(self, {:task_done, all_latest})
        end)
    end

    socket =
      socket
      |> assign(:loading_all_assets, nil)
      |> assign(:latest_ledgers, nil)
      |> assign(:profit_percent, nil)
      |> assign(:portfolio_svgs, nil)
      |> assign(:profit_svg, nil)
      |> assign(:sort_by, :profit_percent)
      |> assign(:asc, true)

    {:ok, socket}
  end

  def handle_info(:working, socket) do
    {:noreply, assign(socket, loading_all_assets: true)}
  end

  def handle_info({:task_done, all_latest}, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(loading_all_assets: false)
      |> assign(:latest_ledgers, all_latest)
      |> assign(:profit_percent, Ledgers.profit_percent(user_id, all_latest))
      |> assign(
        :portfolio_svgs,
        Ledgers.portfolios(user_id, all_latest) |> Enum.map(&portfolio_to_svg(&1))
      )
      |> assign(:profit_svg, Profits.all(user_id) |> profit_svg())

    {:noreply, socket}
  end

  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    sort_by = sort_by |> String.to_atom()
    latest_ledgers = socket.assigns.latest_ledgers
    asc = !socket.assigns.asc

    {:noreply,
     socket
     |> assign(
       sort_by: sort_by,
       asc: asc,
       latest_ledgers: sort_latest_ledgers(latest_ledgers, sort_by, asc)
     )}
  end

  def sort_latest_ledgers(latest_ledgers, sort_by, asc) do
    if sort_by == :name do
      order = if asc, do: :asc, else: :desc

      latest_ledgers
      |> Enum.sort_by(& &1.asset.name, order)
    else
      order = if asc, do: :lt, else: :gt

      latest_ledgers
      |> Enum.sort(fn one, two ->
        sort_by_value_1 = get_in(one, [Access.key!(sort_by)])
        sort_by_value_2 = get_in(two, [Access.key!(sort_by)])
        Decimal.compare(sort_by_value_1, sort_by_value_2) == order
      end)
    end
  end

  defp portfolio_to_svg(portfolio) do
    data =
      portfolio.tag_values
      |> Enum.map(fn tag_value -> [tag_value.name, tag_value.value |> Decimal.to_float()] end)

    dataset = Contex.Dataset.new(data, ["Tag", "Value"])

    opts = [
      mapping: %{category_col: "Tag", value_col: "Value"},
      colour_palette: ["16a34a", "c13584", "499be4", "FF0000", "00f2ea"],
      legend_setting: :legend_bottom,
      data_labels: true,
      title: portfolio.name
    ]

    Contex.Plot.new(dataset, Contex.PieChart, 600, 400, opts) |> Contex.Plot.to_svg()
  end

  defp profit_svg([]), do: nil

  defp profit_svg(profits) do
    data =
      profits
      |> Enum.map(fn profit ->
        [
          profit.date |> DateTime.new!(~T[00:00:00.000], "Etc/UTC"),
          profit.cost |> Decimal.to_float(),
          profit.value |> Decimal.to_float()
        ]
      end)

    dataset = Contex.Dataset.new(data, ["Date", "Cost", "Value"])

    opts = [mapping: %{x_col: "Date", y_cols: ["Cost", "Value"]}]

    Contex.Plot.new(dataset, Contex.LinePlot, 600, 400, opts)
    |> Contex.Plot.to_svg()
  end
end
