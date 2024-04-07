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
      :transacted_at,
      :user_id
    ])
    |> validate_either_or(:from_asset_id)
    |> validate_either_or(:to_asset_id)
    |> validate_maybe_required(:from_qty)
    |> validate_maybe_required(:to_qty)
  end

  defp validate_either_or(changeset, :from_asset_id) do
    if get_field(changeset, :from_asset_id) == nil do
      if get_field(changeset, :to_asset_id) == nil do
        add_error(
          changeset,
          :to_asset_id,
          "From Asset and To Asset cannot be nil at the same time"
        )
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_either_or(changeset, :to_asset_id) do
    if get_field(changeset, :to_asset_id) == nil do
      if get_field(changeset, :from_asset_id) == nil do
        add_error(
          changeset,
          :from_asset_id,
          "From Asset and To Asset cannot be nil at the same time"
        )
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_maybe_required(changeset, :from_qty) do
    if get_field(changeset, :from_asset_id) != nil do
      if get_field(changeset, :from_qty) == nil do
        add_error(
          changeset,
          :from_qty,
          "From Asset and From Quantity need to be filled in at the same time"
        )
      else
        changeset
      end
    else
      changeset
    end
  end

  defp validate_maybe_required(changeset, :to_qty) do
    if get_field(changeset, :to_asset_id) != nil do
      if get_field(changeset, :to_qty) == nil do
        add_error(
          changeset,
          :to_qty,
          "To Asset and To Quantity need to be filled in at the same time"
        )
      else
        changeset
      end
    else
      changeset
    end
  end
end
