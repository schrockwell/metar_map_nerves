defmodule MetarMap.Display do
  @moduledoc """
  Configures and renders LEDs.

  This is a wrapper around Blinkchain, so that we can use mock LEDs in the host environment where Blinkchain isn't available.
  """

  @behaviour MetarMap.Display.Adapter

  def set_pixel(pixel, color) do
    adapter().set_pixel(pixel, color)
  end

  def set_brightness(channel, brightness) do
    adapter().set_brightness(channel, brightness)
  end

  def render do
    adapter().render()
  end

  defp adapter do
    Application.fetch_env!(:metar_map, :display_adapter)
  end
end
