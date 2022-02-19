import Config

# The total number of WS281x LEDs in the string
led_count = 100

# The GPIO pin for WS281x LED data control.
# To see available pins, read: https://github.com/jgarff/rpi_ws281x#gpio-usage
led_pin = 18

# If the light sensor (LDR) is connected, use this GPIO pin.
# Set to false if no light sensor is connected.
ldr_pin = 4

# The stations are an array of tuples containing the full airport identifier and the LED
# index (zero-based).
stations = [
  {"KACK", 3},
  {"KMVY", 5},
  {"KFMH", 6},
  {"KHYA", 7},
  {"KCQX", 8},
  {"KPVC", 9},
  {"KGHG", 10},
  {"KPYM", 11},
  {"KEWB", 12},
  {"KUUU", 13},
  {"KBID", 14},
  {"KWST", 15},
  {"KGON", 16},
  {"KPVD", 18},
  {"KSFZ", 19},
  {"KOWD", 20},
  {"KBOS", 21},
  {"KBED", 22},
  {"KBVY", 23},
  {"KLWM", 24},
  {"KPSM", 25},
  {"KSFM", 26},
  {"KCON", 28},
  {"KMHT", 29},
  {"KASH", 30},
  {"KFIT", 31},
  {"KORH", 32},
  {"KORE", 34},
  {"KEEN", 35},
  {"KVSF", 36},
  {"KRUT", 37},
  {"KGFL", 39},
  {"KDDH", 41},
  {"KAQW", 42},
  {"KPSF", 43},
  {"KBAF", 45},
  {"KBDL", 46},
  {"KHFD", 47},
  {"KIJD", 48},
  {"KSNC", 49},
  {"KHTO", 50},
  {"KFOK", 51},
  {"KISP", 52},
  {"KFRG", 53},
  {"KJFK", 54},
  {"KEWR", 55},
  {"KLGA", 56},
  {"KTEB", 57},
  {"KHPN", 58},
  {"KDXR", 59},
  {"KBDR", 60},
  {"KHVN", 61},
  {"KMMK", 62},
  {"KOXC", 63},
  {"KPOU", 65},
  {"KSWF", 66},
  {"KMSV", 68},
  {"KFWN", 70},
  {"KSMQ", 72},
  {"KTTN", 73},
  {"KRDG", 76},
  {"KABE", 78},
  {"KMPO", 80},
  {"KAVP", 81},
  {"KBGM", 84},
  {"KITH", 86},
  {"KN03", 87},
  {"KSYR", 89},
  {"KRME", 91},
  {"KNY0", 94},
  {"KALB", 96}
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

config :metar_map,
  ldr_pin: ldr_pin,
  stations: stations
