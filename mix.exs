defmodule Riemann.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :riemann,
     version: @version,
     elixir: "~> 1.0",
     deps: deps,
     aliases: [test: "test --no-start"],
     description: "A client for the Riemann event stream processor",
     package: package
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: { Riemann, [] },
      applications: [:logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
     {:exprotobuf, github: "koudelka/exprotobuf", branch: "injection-fix"},
     # {:exprotobuf, "~> 0.8.5"},
     {:gpb, github: "tomas-abrahamsson/gpb", tag: "3.17.2", override: true},
     {:poolboy, "~> 1.4.2"}
    ]
  end

  defp package do
    [contributors: ["Michael Shapiro"],
     licenses: ["MIT"],
     links: %{"GitHub": "https://github.com/koudelka/elixir-riemann",
              "Riemann": "http://riemann.io"}]
  end
end
