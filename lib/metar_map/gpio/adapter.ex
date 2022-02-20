defmodule MetarMap.Gpio.Adapter do
  @callback open(pin :: term, direction :: term) :: {:ok, term}
  @callback set_direction(gpio :: term, direction :: term) :: :ok
  @callback set_interrupts(gpio :: term, interrupts :: term) :: :ok
  @callback write(gpio :: term, value :: term) :: :ok
end
