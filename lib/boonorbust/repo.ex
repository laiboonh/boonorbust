defmodule Boonorbust.Repo do
  use Ecto.Repo,
    otp_app: :boonorbust,
    adapter: Ecto.Adapters.Postgres
end
