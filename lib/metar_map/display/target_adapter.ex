defmodule MetarMap.Display.TargetAdapter do
  @behaviour MetarMap.Display.Adapter

  def set_pixel(pixel, color) do
    color = MetarMap.Display.Color.to_blinkchain(color)
    apply(Blinkchain, :set_pixel, [pixel, color])
  end

  def set_brightness(channel, brightness) do
    apply(Blinkchain, :set_brightness, [channel, brightness])
  end

  def render do
    apply(Blinkchain, :render, [])
  end
end
