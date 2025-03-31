defmodule ShaderGenerator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ShaderGeneratorWeb.Telemetry,
      ShaderGenerator.Repo,
      {DNSCluster, query: Application.get_env(:shader_generator, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ShaderGenerator.PubSub},
      # Start a worker by calling: ShaderGenerator.Worker.start_link(arg)
      # {ShaderGenerator.Worker, arg},
      # Start to serve requests, typically the last entry
      ShaderGeneratorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ShaderGenerator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShaderGeneratorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
