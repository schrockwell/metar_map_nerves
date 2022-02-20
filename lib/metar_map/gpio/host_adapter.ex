defmodule MetarMap.Gpio.HostAdapter do
  @behaviour MetarMap.Gpio.Adapter

  @impl true
  def open(_pin, _direction), do: {:ok, make_ref()}

  @impl true
  def set_direction(_gpio, _direction), do: :ok

  @impl true
  def set_interrupts(_gpio, _interrupts), do: :ok

  @impl true
  def write(_gpio, _value), do: :ok
end
