defmodule Boonorbust.Assets.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "assets" do
    field :name, :string
    field :code, :string
    belongs_to :user, Boonorbust.Accounts.User
    timestamps(type: :utc_datetime)
  end

  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:name, :code, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint([:name, :user_id])
  end
end
