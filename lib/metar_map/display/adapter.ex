defmodule MetarMap.Display.Adapter do
  @callback set_pixel(pixel :: term, color :: term) ::
              :ok | {:error, :invalid, :point} | {:error, :invalid, :color}

  @callback set_brightness(channel :: term, brightness :: term) ::
              :ok | {:error, :invalid, :channel} | {:error, :invalid, :brightness}

  @callback render :: :ok
end
