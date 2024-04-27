defmodule BoonorbustWeb.PageLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Ledgers
  alias Boonorbust.Profits

  def render(assigns) do
    ~H"""
    <%= if @loading_all_assets do %>
      Loading all assets...
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
      <.async_result :let={profit_svg} assign={@profit_svg}>
        <:loading>Loading profit line chart...</:loading>
        <:failed :let={_failure}>there was an error loading the profit line chart</:failed>
        <%= profit_svg %>
      </.async_result>
    </.modal>

    <.async_result :let={portfolio_svgs} assign={@portfolio_svgs}>
      <:loading>Loading portfolio pie charts...</:loading>
      <:failed :let={_failure}>there was an error loading the portfolio pie charts</:failed>
      <%= for portfolio_svg <- portfolio_svgs do %>
        <%= portfolio_svg %>
      <% end %>
    </.async_result>

    <%= if @latest_ledgers do %>
      <.table id="ledgers" rows={@latest_ledgers}>
        <:col :let={ledger} label="Name"><%= ledger.asset.name %></:col>
        <:col :let={ledger} label="Code"><%= ledger.asset.code %></:col>
        <:col :let={ledger} label="Profit %"><%= ledger.profit_percent %>%</:col>
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
          all_latest = Ledgers.all_latest(user_id)
          send(self, {:task_done, all_latest})
        end)
    end

    socket =
      socket
      |> assign(:loading_all_assets, nil)
      |> assign(:latest_ledgers, nil)
      |> assign(:profit_percent, nil)
      |> assign_async(:portfolio_svgs, fn -> {:ok, %{portfolio_svgs: []}} end)
      |> assign_async(:profit_svg, fn -> {:ok, %{profit_svg: nil}} end)

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
      |> assign_async(
        :portfolio_svgs,
        fn ->
          {:ok,
           %{
             portfolio_svgs:
               Ledgers.portfolios(user_id, all_latest) |> Enum.map(&portfolio_to_svg(&1))
           }}
        end
      )
      |> assign_async(:profit_svg, fn ->
        {:ok, %{profit_svg: Profits.all(user_id) |> profit_svg()}}
      end)

    {:noreply, socket}
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
