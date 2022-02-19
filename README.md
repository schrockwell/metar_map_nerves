# 🗺 METAR Map

This is a [Nerves](https://www.nerves-project.org) project to display the weather conditions at local airports using LEDs. [Here's a photo gallery.](https://imgur.com/a/z6Rmb7u)

It was designed to run on a [Raspberry Pi Zero W](https://www.raspberrypi.com/products/raspberry-pi-zero-w/) with a string of [WS2811 LEDs](https://www.amazon.com/gp/product/B01AU6UG70).

![METAR map](https://imgur.com/DdmS8FM.jpg)

## Prerequisites

* [asdf](http://asdf-vm.com) installs of:
  * Elixir 1.13.1
  * Erlang 24.1.7
* [Nerves installation](https://hexdocs.pm/nerves/installation.html)
* [direnv](https://direnv.net) (optional)

## Building the firmware

1. Copy `.envrc-example` to `.envrc` and modify it the environment variables as appropriate.

2. Edit `config/stations.exs` with the list of METAR station IDs.

3. Build firmware.

    ```bash
    direnv allow
    # -> or just `source .envrc`

    mix deps.get
    mix firmware
    ```

4. Burn or upload the firmware.

    ```bash
    # Burn to an SD card
    mix burn

    # -OR- upload to an existing Pi
    mix upload metar-map.local
    ```
