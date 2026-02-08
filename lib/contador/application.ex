defmodule Contador.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ContadorWeb.Telemetry,
      Contador.Repo,
      {DNSCluster, query: Application.get_env(:contador, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Contador.PubSub},
      # Start a worker by calling: Contador.Worker.start_link(arg)
      # {Contador.Worker, arg},
      # Start to serve requests, typically the last entry
      ContadorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Contador.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ContadorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
