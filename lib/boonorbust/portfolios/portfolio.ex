defmodule Boonorbust.Portfolios.Portfolio do
  alias Boonorbust.Tags
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "portfolios" do
    field :name, :string
    belongs_to :user, Boonorbust.Accounts.User
    many_to_many :tags, Boonorbust.Tags.Tag, join_through: "portfolios_tags", on_replace: :delete
  end

  def changeset(portfolio, attrs) do
    tags = Tags.get_by_ids(Map.get(attrs, :tag_ids, []))

    portfolio
    |> cast(attrs, [:name, :user_id])
    |> put_assoc(:tags, tags)
    |> validate_required([:name, :user_id])
    |> unique_constraint([:name, :user_id])
  end
end
