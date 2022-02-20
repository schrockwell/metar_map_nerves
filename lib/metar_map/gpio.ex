defmodule MetarMap.Gpio do
  @moduledoc """
  Configures and accesses GPIO pins.

  This is a wrapper around Circuits.GPIO, so that we can use mock GPIO in the host environment where Circuits.GPIO isn't available.
  """

  @behaviour MetarMap.Gpio.Adapter

  @impl true
  def open(pin, direction) do
    adapter().open(pin, direction)
  end

  @impl true
  def set_direction(gpio, direction) do
    adapter().set_direction(gpio, direction)
  end

  @impl true
  def set_interrupts(gpio, interrupts) do
    adapter().set_interrupts(gpio, interrupts)
  end

  @impl true
  def write(gpio, value) do
    adapter().write(gpio, value)
  end

  defp adapter do
    Application.fetch_env!(:metar_map, :gpio_adapter)
  end
end
