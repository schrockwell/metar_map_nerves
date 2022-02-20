# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

config :metar_map, target: Mix.target()

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1645219245"

# Configures the Phoenix endpoint
config :metar_map, MetarMapWeb.Endpoint,
  http: [port: 4000],
  url: [host: "localhost", port: 4000],
  secret_key_base: "K93bkfXRGqOFzFsghkZeQvXLJ+aJIPjtIquFjxE4lPktFcr1aS8EaQaMPkvEaHGR"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Station and LED config
import_config "stations.exs"

if Mix.target() == :host or Mix.target() == :"" do
  import_config "host.exs"
else
  import_config "target.exs"
end
