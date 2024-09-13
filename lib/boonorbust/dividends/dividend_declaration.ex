defmodule Boonorbust.Dividends.DividendDeclaration do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "dividend_declarations" do
    field :currency, :string
    field :amount, :decimal
    field :ex_date, :date
    field :payable_date, :date

    belongs_to :asset, Boonorbust.Assets.Asset
  end

  def changeset(history, attrs) do
    history
    |> cast(attrs, [:currency, :amount, :ex_date, :payable_date, :asset_id])
    |> validate_required([:currency, :amount, :ex_date, :payable_date, :asset_id])
  end
end
