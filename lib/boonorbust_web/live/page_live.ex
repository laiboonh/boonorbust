defmodule BoonorbustWeb.PageLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Ledgers
  alias Boonorbust.Profits
  alias Phoenix.LiveView.AsyncResult

  def render(assigns) do
    ~H"""
    <%= if @ledgers.loading do %>
      <.spinner text="Loading all assets..." />
    <% end %>

    <%= if profit_percent = @profit_percent.ok? && @profit_percent.result do %>
      <%= if profit_percent |> Decimal.positive?() do %>
        <p
          phx-click={show_modal("profit-svg-modal")}
          class="text-green-700 text-2xl underline decoration-double text-right"
        >
          <%= profit_percent %>%
        </p>
      <% else %>
        <p
          phx-click={show_modal("profit-svg-modal")}
          class="text-red-700 text-2xl underline decoration-double text-right"
        >
          <%= profit_percent %>%
        </p>
      <% end %>
    <% end %>

    <.modal id="profit-svg-modal">
      <%= if profit_svg = @profit_svg.ok? && @profit_svg.result do %>
        <%= profit_svg %>
      <% end %>
    </.modal>

    <%= if portfolio_svgs = @portfolio_svgs.ok? && @portfolio_svgs.result do %>
      <%= for portfolio_svg <- portfolio_svgs do %>
        <%= portfolio_svg %>
      <% end %>
    <% end %>

    <%= if ledgers = @ledgers.ok? && @ledgers.result do %>
      <.table id="ledgers" rows={ledgers}>
        <:col :let={ledger} label="<span phx-click='sort' phx-value-sort_by='name'>Name</span>">
          <%= ledger.asset.name %><br />
          <p class="text-slate-400"><%= ledger.asset.code %></p>
        </:col>
        <:col
          :let={ledger}
          label="<span phx-click='sort' phx-value-sort_by='total_cost_in_local_currency'>Cost in local currency</span>"
        >
          <%= ledger.total_cost_in_local_currency %>
        </:col>
        <:col
          :let={ledger}
          label="<span phx-click='sort' phx-value-sort_by='total_value_in_local_currency'>Value in local currency</span>"
        >
          <%= ledger.total_value_in_local_currency %>
        </:col>
        <:col
          :let={ledger}
          label="<span phx-click='sort' phx-value-sort_by='profit_percent'>Profit %</span>"
        >
          <%= ledger.profit_percent %>
        </:col>
        <:col
          :let={ledger}
          label="<span phx-click='sort' phx-value-sort_by='value_percent'>Value %</span>"
        >
          <%= ledger.value_percent %>
        </:col>
      </.table>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    sort_by = :profit_percent
    asc = true

    socket =
      socket
      |> assign(:sort_by, sort_by)
      |> assign(:asc, asc)
      |> assign_async([:ledgers, :profit_percent, :portfolio_svgs, :profit_svg], fn ->
        ledgers = Ledgers.all(user_id)

        {total_value, total_cost} = Ledgers.total_value_total_cost(ledgers)

        ledgers =
          Ledgers.calculate_value_percent(ledgers, total_value) |> sort_ledgers(sort_by, asc)

        profit_percent = Ledgers.profit_percent(user_id, total_value, total_cost)

        portfolio_svgs = Ledgers.portfolios(user_id, ledgers) |> Enum.map(&portfolio_to_svg(&1))

        profit_svg = Profits.all(user_id) |> profit_svg()

        {:ok,
         %{
           ledgers: ledgers,
           profit_percent: profit_percent,
           portfolio_svgs: portfolio_svgs,
           profit_svg: profit_svg
         }}
      end)

    {:ok, socket}
  end

  def handle_info(:working, socket) do
    {:noreply, assign(socket, loading_all_assets: true)}
  end

  def handle_event("sort", %{"sort_by" => sort_by}, socket) do
    sort_by = sort_by |> String.to_atom()
    ledgers_async_result = socket.assigns.ledgers
    asc = !socket.assigns.asc

    {:noreply,
     socket
     |> assign(
       sort_by: sort_by,
       asc: asc,
       ledgers:
         AsyncResult.ok(
           ledgers_async_result,
           sort_ledgers(ledgers_async_result.result, sort_by, asc)
         )
     )}
  end

  defp sort_ledgers(ledgers, sort_by, asc) do
    if sort_by == :name do
      order = if asc, do: :asc, else: :desc

      ledgers
      |> Enum.sort_by(& &1.asset.name, order)
    else
      order = if asc, do: :lt, else: :gt

      ledgers
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
