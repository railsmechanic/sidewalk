defmodule Sidewalk.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sidewalk,
      version: "0.2.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
   ]
  end

  def application do
    [applications: [:logger, :crypto],
     mod: {Sidewalk, []}]
  end

  defp deps do
    [
      {:redix, "~> 0.4.0"},
      {:poolboy, "~> 1.5"},
      {:poison, "~> 2.2"},
      {:ex_doc, "~> 0.13.0", only: [:dev]},
      {:earmark, "~> 1.0.1", only: [:dev]}
    ]
  end

  defp description do
    """
    Sidewalk is an Elixir client compatible with Sidekiq, the »simple, efficient background processing library for Ruby«.
    """
  end

  defp package do
    [
      name: :sidewalk,
      maintainers: ["Matthias Kalb"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/railsmechanic/sidewalk"
      }
    ]
  end
end
