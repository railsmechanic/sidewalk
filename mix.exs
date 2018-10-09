defmodule Sidewalk.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sidewalk,
      version: "0.4.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto], mod: {Sidewalk, []}]
  end

  defp deps do
    [
      {:redix, "~> 0.8"},
      {:poolboy, "~> 1.5.1"},
      {:poison, "~> 3.1.0"},
      {:ex_doc, "~> 0.18.3", only: [:dev]},
      {:earmark, "~> 1.2.5", only: [:dev]},
      {:dialyxir, "~> 0.5.1", only: [:dev], runtime: false}
    ]
  end

  defp description do
    """
    Sidewalk is an Elixir client which is compatible with Sidekiq, the »simple, efficient background processing library for Ruby«.
    """
  end

  defp package do
    [
      name: :sidewalk,
      licenses: ["MIT"],
      maintainers: [],
      links: %{
        "GitHub" => "https://github.com/railsmechanic/sidewalk"
      }
    ]
  end
end
