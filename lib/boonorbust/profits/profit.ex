defmodule Boonorbust.Profits.Profit do
  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "profits" do
    field :date, :date
    field :value, :decimal
    belongs_to :user, Boonorbust.Accounts.User
  end
end
