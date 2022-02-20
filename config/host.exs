import Config

# Add configuration that is only needed when running on the host here.

config :metar_map,
  display_adapter: MetarMap.Display.HostAdapter,
  gpio_adapter: MetarMap.Gpio.HostAdapter,
  dets_config_path: "/tmp/dets_config",
  ldr_pin: 42
