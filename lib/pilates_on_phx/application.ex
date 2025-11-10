defmodule PilatesOnPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PilatesOnPhxWeb.Telemetry,
      PilatesOnPhx.Repo,
      {DNSCluster, query: Application.get_env(:pilates_on_phx, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PilatesOnPhx.PubSub},
      # Start a worker by calling: PilatesOnPhx.Worker.start_link(arg)
      # {PilatesOnPhx.Worker, arg},
      # Start to serve requests, typically the last entry
      PilatesOnPhxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PilatesOnPhx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PilatesOnPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
