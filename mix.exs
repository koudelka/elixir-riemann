defmodule Riemann.Mixfile do
  use Mix.Project

  @version "0.0.16"

  def project do
    [app: :riemann,
     version: @version,
     elixir: "~> 1.4",
     deps: deps(),
     aliases: [test: "test --no-start"],
     description: "A client for the Riemann event stream processor",
     package: package()
    ]
  end

  def application do
    [
      mod: { Riemann, [] },
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
     {:exprotobuf, "~> 1.0.0"},
     {:honeydew, github: "koudelka/honeydew", branch: "gen_stage"},
    ]
  end

  defp package do
    [maintainers: ["Michael Shapiro"],
     licenses: ["MIT"],
     links: %{"GitHub": "https://github.com/koudelka/elixir-riemann",
              "Riemann": "http://riemann.io"}]
  end
end
