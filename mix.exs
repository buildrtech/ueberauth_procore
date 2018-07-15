defmodule UeberauthProcore.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ueberauth_procore,
      version: @version,
      name: "Ueberauth Procore",
      package: package(),
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      source_url: "https://github.com/buildrtech/ueberauth_procore",
      homepage_url: "https://github.com/buildrtech/ueberauth_procore",
      description: description(),
      deps: deps(),
      docs: docs(),
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:oauth2, "~> 0.9"},
      {:ueberauth, "~> 0.4"},

      # dev/test dependencies
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end

  defp docs do
    [extras: ["README.md", "CONTRIBUTING.md"]]
  end

  defp description do
    "An Ueberauth strategy for using Procore to authenticate your users"
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md"],
     maintainers: ["Michael Stock"],
     licenses: ["MIT"],
     links: %{"Procore": "https://github.com/buildrtech/ueberauth_procore"}]
  end
end
