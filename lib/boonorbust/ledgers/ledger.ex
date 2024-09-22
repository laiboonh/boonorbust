defmodule Boonorbust.Ledgers.Ledger do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "ledgers" do
    field :inventory_qty, :decimal
    field :inventory_cost, :decimal
    field :weighted_average_cost, :decimal
    field :unit_cost, :decimal
    field :total_cost, :decimal
    field :qty, :decimal
    field :transacted_at, :date
    field :latest, :boolean

    belongs_to :trade, Boonorbust.Trades.Trade
    belongs_to :asset, Boonorbust.Assets.Asset

    field :latest_price, :decimal, virtual: true
    field :latest_value, :decimal, virtual: true
    field :profit_percent, :decimal, virtual: true
  end

  def changeset(ledger, attrs) do
    ledger
    |> cast(attrs, [
      :inventory_qty,
      :inventory_cost,
      :weighted_average_cost,
      :unit_cost,
      :total_cost,
      :qty,
      :latest,
      :trade_id,
      :asset_id
    ])
    |> validate_required([
      :inventory_qty,
      :inventory_cost,
      :weighted_average_cost,
      :unit_cost,
      :total_cost,
      :qty,
      :latest,
      :trade_id,
      :asset_id
    ])
  end
end
