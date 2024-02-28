defmodule Measure.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Measure.TaskSupervisor},
      {
        Postgrex,
        hostname: "localhost",
        port: 5433,
        database: "sharding",
        username: "postgresnode1user",
        password: "postgresnode1pass",
        pool_size: 100,
        name: :postgrex,
      },
      {Measure.Cache, :requests_cache}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Measure.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
