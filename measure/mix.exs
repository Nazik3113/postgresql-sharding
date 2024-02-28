defmodule Measure.MixProject do
  use Mix.Project

  def project do
    [
      releases: [
        measure: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ],
      app: :measure,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Measure.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4.1"},
      {:postgrex, "~> 0.17.4"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
