defmodule MetarMap.MixProject do
  use Mix.Project

  @app :metar_map
  @version "0.1.0"
  @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4, :bbb, :osd32mp1, :x86_64]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.10"],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      build_embedded: true,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MetarMap.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # NERVES - Dependencies for all targets
      {:nerves, "~> 1.7.4", runtime: false},
      {:shoehorn, "~> 0.7.0"},
      {:ring_logger, "~> 0.8.1"},
      {:toolshed, "~> 0.2.13"},

      # NERVES - Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.11.3", targets: @all_targets},
      {:nerves_pack, "~> 0.6.0", targets: @all_targets},

      # MY APP
      {:phoenix, "~> 1.6.6"},
      {:phoenix_html, "~> 3.2.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.1"},
      {:sweet_xml, "~> 0.6.5"},
      {:blinkchain,
       git: "https://github.com/valiot/blinkchain.git",
       ref: "master-blinkchain",
       submodules: true,
       targets: @all_targets},
      {:httpoison, "~> 1.5"},
      {:phoenix_ecto, "~> 4.4"},
      {:circuits_gpio, "~> 0.3", targets: @all_targets},
      {:phoenix_live_view, "~> 0.17.6"},
      {:floki, ">= 0.30.0", only: :test},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:phoenix_live_reload, "~> 1.2"},
      {:phoenix_pubsub, "~> 2.0"},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      # {:nerves_system_rpi, "1.20.0", runtime: false, targets: :rpi},
      {:nerves_system_rpi0, "~> 1.20", runtime: false, targets: :rpi0},
      # {:nerves_system_rpi2, "1.20.0", runtime: false, targets: :rpi2},
      # {:nerves_system_rpi3, "1.20.0", runtime: false, targets: :rpi3},
      {:nerves_system_rpi3a, "~> 1.20", runtime: false, targets: :rpi3a}
      # {:nerves_system_rpi4, "1.20.0", runtime: false, targets: :rpi4},
      # {:nerves_system_bbb, "~> 2.12", runtime: false, targets: :bbb},
      # {:nerves_system_osd32mp1, "~> 0.8", runtime: false, targets: :osd32mp1},
      # {:nerves_system_x86_64, "1.20.0", runtime: false, targets: :x86_64}
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end

  defp aliases do
    [
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      firmware: ["assets.deploy", "firmware"]
    ]
  end
end
