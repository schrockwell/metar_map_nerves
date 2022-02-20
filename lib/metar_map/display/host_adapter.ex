defmodule MetarMap.Display.HostAdapter do
  @behaviour MetarMap.Display.Adapter

  def set_pixel(_pixel, _color), do: :ok

  def set_brightness(_channel, _brightness), do: :ok

  def render, do: :ok
end
