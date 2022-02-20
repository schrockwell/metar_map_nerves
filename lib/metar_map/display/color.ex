defmodule MetarMap.Display.Color do
  @moduledoc """
  Represents an LED color.

  This is designed to be a wrapper around %Blinkchain.Color{}.
  """
  defstruct r: 0, g: 0, b: 0, w: 0

  def to_blinkchain(%{r: r, g: g, b: b, w: w}) do
    struct!(Blinkchain.Color, r: r, g: g, b: b, w: w)
  end
end
