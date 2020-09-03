defmodule Concoction.MixProject do
  use Mix.Project

  def project do
    [
      app: :concoction,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Docs
      name: "Concoction",
      source_url: "https://github.com/jb3/concoction",
      homepage_url: "https://concoction.seph.club/",
      docs: [
        main: "Concoction",
        logo: "logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      applications: [:tesla, :gun],
      mod: {Concoction, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.3.0"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:jason, ">= 1.0.0"},
      {:gun, "~> 1.3.0"},
      {:idna, "~> 6.0"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
