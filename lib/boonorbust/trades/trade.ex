defmodule Boonorbust.Trades.Trade do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "trades" do
    belongs_to :from_asset, Boonorbust.Assets.Asset
    belongs_to :to_asset, Boonorbust.Assets.Asset
    field :from_qty, :decimal
    field :to_qty, :decimal
    field :to_asset_unit_cost, :decimal
    field :transacted_at, :date
    belongs_to :user, Boonorbust.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(trade, attrs) do
    trade
    |> cast(attrs, [
      :from_asset_id,
      :to_asset_id,
      :from_qty,
      :to_qty,
      :to_asset_unit_cost,
      :transacted_at,
      :user_id
    ])
    |> validate_required([
      :from_asset_id,
      :to_asset_id,
      :from_qty,
      :to_qty,
      :to_asset_unit_cost,
      :transacted_at,
      :user_id
    ])
  end
end
