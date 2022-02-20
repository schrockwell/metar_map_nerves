import Config

# Add configuration that is only needed when running on the host here.

config :metar_map,
  display_adapter: MetarMap.Display.HostAdapter,
  gpio_adapter: MetarMap.Gpio.HostAdapter,
  dets_config_path: "/tmp/dets_config",
  ldr_pin: 42

config :metar_map, MetarMapWeb.Endpoint,
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]
