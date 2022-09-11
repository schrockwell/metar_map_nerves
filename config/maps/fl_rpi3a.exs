import Config

# The total number of WS281x LEDs in the string
led_count = 50

# The GPIO pin for WS281x LED data control.
# To see available pins, read: https://github.com/jgarff/rpi_ws281x#gpio-usage
led_pin = 18

# LDR input pin
ldr_pin = false

# Airports
stations = [
  {"KZPH", 1},
  {"KBKV", 2},
  {"KCLW", 3},
  {"KPIE", 4},
  {"KTPA", 5},
  {"KSPG", 6},
  {"KMCF", 7},
  {"KVDF", 8},
  {"KPCM", 9},
  {"KLAL", 10},
  {"KBOW", 11},
  {"KGIF", 12},
  {"KISM", 13},
  {"KMCO", 14},
  {"KSFB", 15},
  {"KLEE", 16},
  {"KCGC", 17},
  {"KTIX", 18},
  {"KTTS", 19},
  {"KXMR", 20},
  {"KCOF", 21},
  {"KMLB", 22},
  {"KX26", 23},
  {"KVRB", 24},
  {"KFPR", 25},
  {"KSUA", 26},
  {"KPBI", 27},
  {"KLNA", 28},
  {"KBCT", 29},
  {"KPMP", 30},
  {"KFXE", 31},
  {"KFLL", 32},
  {"KHWO", 33},
  {"KOPF", 34},
  {"KMIA", 35},
  {"KTMB", 36},
  {"KHST", 37},
  {"KK70", 38},
  {"KMTH", 39},
  {"KNQX", 40},
  {"KMKY", 41},
  {"KAPF", 42},
  {"KRSW", 43},
  {"KFMY", 44},
  {"KIMM", 45},
  {"K2IS", 46},
  {"KPDG", 47},
  {"K54A", 48},
  {"KVNC", 49},
  {"KSRQ", 50}
  # {"KOBE", 51},
  # {"KSEF", 52},
  # {"KAGR", 53}
]

config :metar_map,
  ldr_pin: ldr_pin,
  stations: stations

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
