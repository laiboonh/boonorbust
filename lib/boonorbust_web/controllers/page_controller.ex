defmodule BoonorbustWeb.PageController do
  alias Boonorbust.Ledgers
  alias Boonorbust.Profits

  use BoonorbustWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)

    case Map.get(conn.assigns, :current_user) do
      nil ->
        render(conn, :home,
          latest_ledgers: nil,
          profit_percent: nil,
          portfolio_svgs: nil,
          profit_svg: nil
        )

      current_user ->
        all_latest =
          Ledgers.all_non_currency_latest(current_user.id)
          |> Enum.sort(fn %{profit_percent: pp1}, %{profit_percent: pp2} ->
            Decimal.compare(pp1, pp2) == :lt
          end)

        render(conn, :home,
          latest_ledgers: all_latest,
          profit_percent: Ledgers.profit_percent(current_user.id, all_latest),
          portfolio_svgs:
            Ledgers.portfolios(current_user.id, all_latest) |> Enum.map(&portfolio_to_svg(&1)),
          profit_svg: Profits.all(current_user.id) |> profit_svg()
        )
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
