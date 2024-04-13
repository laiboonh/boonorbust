defmodule Boonorbust.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "tags" do
    field :name, :string
    belongs_to :user, Boonorbust.Accounts.User
  end

  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint([:name, :user_id])
  end
end
