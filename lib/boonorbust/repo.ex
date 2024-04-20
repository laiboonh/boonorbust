defmodule Boonorbust.Repo do
  use Ecto.Repo,
    otp_app: :boonorbust,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
