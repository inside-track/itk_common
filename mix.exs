defmodule ITKCommon.MixProject do
  use Mix.Project

  @project_url "https://github.com/inside-track/itk_common"
  @version "0.0.2"

  def project do
    [
      app: :itk_common,
      version: @version,
      elixir: "~> 1.8",
      description: "Provides common logic for all ITK elixir projects",
      source_url: @project_url,
      homepage_url: @project_url,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: [main: "readme", extras: ["README.md"]],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: true
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ITKCommon, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      # {:httpoison, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:plug, "> 0.0.0"},
      {:csv, "~> 2.3.0"},
      {:timex, "~> 3.1"},
      {:poolboy, "~> 1.5"},
      {:redix, "~> 0.9.0"},
      {:ex_doc, "~> 0.19.0", only: :dev},
      {:remote_ip, git: "https://github.com/inside-track/remote_ip.git", branch: "master"},
      {:credo, git: "https://github.com/rrrene/credo.git", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:itk_queue, "~> 0.12.1"}
    ]
  end

  defp package do
    [
      maintainers: ["Grady Griffin"],
      links: %{
        "GitHub" => @project_url
      }
    ]
  end
end
