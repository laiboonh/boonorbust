defmodule Boonorbust.Assets.Asset do
  alias Boonorbust.Tags
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "assets" do
    field :name, :string
    field :code, :string
    field :type, Ecto.Enum, values: [stock: 1, fund: 2, currency: 3, commodity: 4, crypto: 5]
    field :root, :boolean, default: false
    belongs_to :user, Boonorbust.Accounts.User
    many_to_many :tags, Boonorbust.Tags.Tag, join_through: "assets_tags", on_replace: :delete
    timestamps(type: :utc_datetime)
  end

  def changeset(asset, attrs) do
    tags = Tags.get_by_ids(Map.get(attrs, :tag_ids, []))

    asset
    |> cast(attrs, [:name, :code, :type, :root, :user_id])
    |> put_assoc(:tags, tags)
    |> validate_required([:name, :code, :type, :user_id])
    |> unique_constraint([:code, :type, :user_id])
  end
end
