import Config

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_pack],
  app: Mix.Project.config()[:app]

# Nerves Runtime can enumerate hardware devices and send notifications via
# SystemRegistry. This slows down startup and not many programs make use of
# this feature.

config :nerves_runtime, :kernel, use_system_registry: false

# Erlinit can be configured without a rootfs_overlay. See
# https://github.com/nerves-project/erlinit/ for more information on
# configuring erlinit.

config :nerves,
  erlinit: [
    hostname_pattern: "nerves-%s"
  ]

# Configure the device for SSH IEx prompt access and firmware updates
#
# * See https://hexdocs.pm/nerves_ssh/readme.html for general SSH configuration
# * See https://hexdocs.pm/ssh_subsystem_fwup/readme.html for firmware updates

keys =
  [
    Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
  ]
  |> Enum.filter(&File.exists?/1)

if keys == [],
  do:
    Mix.raise("""
    No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config.exs for this error message.
    """)

config :nerves_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)

# Configure the network using vintage_net
# See https://github.com/nerves-networking/vintage_net for more information
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :dhcp}
     }},
    {"wlan0",
     %{
       type: VintageNetWiFi,
       vintage_net_wifi: %{
         networks: [
           %{
             key_mgmt: :wpa_psk,
             ssid: System.fetch_env!("VINGATE_NET_WIFI_SSID"),
             psk: System.fetch_env!("VINTAGE_NET_WIFI_PSK")
           }
         ]
       },
       ipv4: %{method: :dhcp}
     }}
  ]

config :mdns_lite,
  # The `host` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For the official Nerves systems, this
  # is "nerves-<4 digit serial#>.local".  mdns_lite also advertises
  # "nerves.local" for convenience. If more than one Nerves device is on the
  # network, delete "nerves" from the list.

  host: [:hostname, "metar-map"],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "sftp-ssh",
      transport: "tcp",
      port: 22
    },
    %{
      protocol: "epmd",
      transport: "tcp",
      port: 4369
    },
    %{
      protocol: "http",
      transport: "tcp",
      port: 80
    }
  ]

# Configures the Phoenix endpoint
config :metar_map_nerves, MetarMapWeb.Endpoint,
  http: [port: 80],
  url: [host: "metar-map.local", port: 80],
  server: true,
  # cache_static_manifest: "priv/static/cache_manifest.json",
  render_errors: [view: MetarMapWeb.ErrorView, accepts: ~w(html json)]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Blinkchain gamma config
import_config "blinkchain.exs"

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"

#### METAR MAP CONFIG ###

# The total number of WS281x LEDs in the string
led_count = 100

# The GPIO pin for WS281x LED data control.
# To see available pins, read: https://github.com/jgarff/rpi_ws281x#gpio-usage
led_pin = 18

# If the light sensor (LDR) is connected, use this GPIO pin.
# Set to false if no light sensor is connected.
ldr_pin = 1

# The stations are an array of tuples containing the full airport identifier and the LED
# index (zero-based).
stations = [
  {"KHFD", 1},
  {"KBDL", 2},
  {"KHYA", 3},
  {"KMWN", 4}
]

# --- No need to change anything below ---

config :blinkchain,
  canvas: {led_count, 1},
  # Default DMA channel 5 does not work for Nerves for some reason, but 4 works (via experimentation)
  # https://github.com/GregMefford/blinkchain/issues/27#issuecomment-777936127
  dma_channel: 4

config :blinkchain, :channel0,
  pin: led_pin,
  type: :rgb,
  arrangement: [
    %{
      type: :strip,
      origin: {0, 0},
      count: led_count,
      direction: :right
    }
  ]

config :metar_map_nerves,
  ldr_pin: ldr_pin,
  stations: stations
