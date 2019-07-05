defmodule Oauth.MixProject do
  use Mix.Project

  def project do
    [
      app: :oauth,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:mock, "0.3.3", only: :test},
      {:ext, git: "https://github.com/outcastby/ext.git"},
      {:sdk, git: "https://github.com/outcastby/sdk"},
      {:joken, "~> 2.0"},
      {:extwitter, "~> 0.8"},
      {:ecto_enum, "~> 1.0"}
    ]
  end
end
