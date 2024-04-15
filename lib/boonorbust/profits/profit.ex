defmodule Boonorbust.Profits.Profit do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "profits" do
    field :date, :date
    field :value, :decimal
    belongs_to :user, Boonorbust.Accounts.User
  end

  def changeset(profit, attrs) do
    profit
    |> cast(attrs, [:date, :value, :user_id])
    |> validate_required([:date, :value, :user_id])
  end
end
