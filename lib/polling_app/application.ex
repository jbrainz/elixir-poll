defmodule PollingApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PollingAppWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:polling_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PollingApp.PubSub},
      {Finch, name: PollingApp.Finch},
      {PollingApp.PollManager.PollManager, []},
      PollingAppWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PollingApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PollingAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
