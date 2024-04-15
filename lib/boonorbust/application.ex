defmodule Boonorbust.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Oban.Telemetry.attach_default_logger()

    children = [
      BoonorbustWeb.Telemetry,
      Boonorbust.Repo,
      {Oban, Application.fetch_env!(:boonorbust, Oban)},
      {DNSCluster, query: Application.get_env(:boonorbust, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Boonorbust.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Boonorbust.Finch},
      # Start a worker by calling: Boonorbust.Worker.start_link(arg)
      # {Boonorbust.Worker, arg},
      # Start to serve requests, typically the last entry
      BoonorbustWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Boonorbust.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BoonorbustWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
