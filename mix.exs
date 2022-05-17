defmodule StreamProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :stream_processor,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {StreamProcessor, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:unpack, "~> 0.1.7"},
      {:ex_doc, "~> 0.28.0"},
      {:eventsource_ex, "~> 1.1.0"},
      {:poison, "~> 3.1"},
      {:mongodb, "~>0.5.1"}
    ]
  end
end
