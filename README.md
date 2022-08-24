# 🗺 METAR Map

This is a [Nerves](https://www.nerves-project.org) project to display the weather conditions at local airports using LEDs. [Here's a photo gallery.](https://imgur.com/a/z6Rmb7u)

It was designed to run on a [Raspberry Pi Zero W](https://www.raspberrypi.com/products/raspberry-pi-zero-w/) with a string of [WS2811 LEDs](https://www.amazon.com/gp/product/B01AU6UG70).

![METAR map](https://imgur.com/DdmS8FM.jpg)

## Prerequisites

- [asdf](http://asdf-vm.com) installs of:
  - Elixir 1.13.1
  - Erlang 24.1.7
- [Nerves installation](https://hexdocs.pm/nerves/installation.html)
- [direnv](https://direnv.net) (optional)

## Building the firmware

1. Copy an existing map config file, e.g. `config/maps/ny_rpi0.exs`, and modify.

2. Copy `.envrc-example` to `.envrc` and modify the environment variables.

3. Set up the environment.

   ```bash
   direnv allow
   asdf install
   mix archive.install hex nerves_bootstrap
   mix deps.get
   ```

4. Build and upload the firmware.

   ```bash
   mix firmware

   # Burn to an SD card
   mix burn

   # -OR- upload to an existing Pi
   mix upload metar-map.local
   ```

## Testing locally on the host machine

```bash
MIX_TARGET=host iex -S mix phx.server
```
