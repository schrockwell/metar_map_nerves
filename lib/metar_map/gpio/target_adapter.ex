defmodule MetarMap.Gpio.TargetAdapter do
  @behaviour MetarMap.Gpio.Adapter

  @impl true
  def open(pin, direction) do
    apply(Circuits.GPIO, :open, [pin, direction])
  end

  @impl true
  def set_direction(gpio, direction) do
    apply(Circuits.GPIO, :set_direction, [gpio, direction])
  end

  @impl true
  def set_interrupts(gpio, interrupts) do
    apply(Circuits.GPIO, :set_interrupts, [gpio, interrupts])
  end

  @impl true
  def write(gpio, value) do
    apply(Circuits.GPIO, :write, [gpio, value])
  end
end
