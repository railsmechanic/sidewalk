defmodule Sidewalk.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sidewalk,
      version: "0.2.2",
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
      {:poison, "~> 3.0"},
      {:ex_doc, "~> 0.14.3", only: [:dev]},
      {:earmark, "~> 1.0.2", only: [:dev]}
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
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/railsmechanic/sidewalk"
      }
    ]
  end
end
