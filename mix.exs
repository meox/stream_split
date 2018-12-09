defmodule StreamSplit.MixProject do
  use Mix.Project

  def project do
    [
      app: :file_stream_split,
      version: "0.1.2",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "FileStreamSplit",
      source_url: "https://github.com/meox/stream_split"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp description() do
    "Stream a file splitting it using a token"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "file_stream_split",
      # These are the default files included in the package
      files: ~w(lib config .formatter.exs mix.exs README.md lib doc),
      licenses: ["BSD"],
      links: %{"GitHub" => "https://github.com/meox/stream_split"}
    ]
  end
end
