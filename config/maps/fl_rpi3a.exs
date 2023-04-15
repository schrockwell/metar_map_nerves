import Config

# The total number of WS281x LEDs in the string
led_count = 100

# The GPIO pin for WS281x LED data control.
# To see available pins, read: https://github.com/jgarff/rpi_ws281x#gpio-usage
led_pin = 18

# LDR input pin
ldr_pin = false

# WiFi reset pin
wifi_reset_pin = 21

# Airports (zero-indexed)
stations = [
  {"KHST", 2},
  # Not reporting:
  {"X51", 3},
  {"KTMB", 4},
  {"KMIA", 5},
  {"KOPF", 6},
  {"KHWO", 7},
  {"KFLL", 8},
  {"KFXE", 9},
  {"KPMP", 10},
  {"KBCT", 11},
  {"KLNA", 12},
  {"KPBI", 13},
  # Skip 14
  {"KSUA", 15},
  {"KFPR", 16},
  {"KVRB", 17},
  {"KX26", 18},
  {"KMLB", 19},
  {"KCOF", 20},
  {"KXMR", 21},
  {"KTTS", 22},
  {"KTIX", 23},
  # Skip 24
  {"KSFB", 25},
  # Not reporting:
  {"KORL", 26},
  {"KMCO", 27},
  {"KISM", 28},
  # Skip 29
  {"KLEE", 30},
  # Skip 31
  {"KINF", 32},
  {"KBKV", 33},
  {"KZPH", 34},
  # Skip 35
  {"KCLW", 36},
  {"KPIE", 37},
  {"KSPG", 38},
  {"KMCF", 39},
  {"KTPA", 40},
  {"KVDF", 41},
  {"KPCM", 42},
  {"KLAL", 43},
  {"KBOW", 44},
  {"KX07", 45},
  # Not reporting:
  {"KAGR", 46},
  {"KSEF", 47},
  # Skip 48
  {"KOBE", 49},
  {"K2IS", 50},
  # Skip 51-54
  {"KSRQ", 55},
  {"KVNC", 56},
  # Skip 57
  {"KPGD", 58},
  {"KFMY", 59},
  {"KRSW", 60},
  {"KIMM", 61},
  # Skip 62
  {"KAPF", 63},
  # Not reporting:
  {"KMKY", 64},
  # Skip 65-68
  {"KEYW", 69},
  {"KNQX", 70},
  # Skip 71
  {"KMTH", 72}
]

config :metar_map,
  ldr_pin: ldr_pin,
  stations: stations,
  wifi_reset_pin: wifi_reset_pin

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
