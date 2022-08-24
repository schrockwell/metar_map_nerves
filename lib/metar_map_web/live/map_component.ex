defmodule MetarMapWeb.MapComponent do
  use MetarMapWeb, :component

  alias MetarMap.Station

  def map(assigns) do
    ~H"""
    <div class="p-4 md:p-10 w-full border shadow-lg rounded-xl bg-gray-100 mb-6" style="height: 50vw">
      <div class="relative w-full h-full">
        <%= for led <- @leds do %>
            <div class="absolute border rounded-full" style={station_position_style(led)} />
        <% end %>
      </div>
    </div>
    """
  end

  defp station_position_style(%{station: %Station{position: {x, y}}} = led) do
    bg_color = led.latest_color |> MetarMap.brighten(0.9) |> color_to_hex()
    border_color = led.latest_color |> MetarMap.brighten(0.7) |> color_to_hex()

    "background-color: #{bg_color}; border-color: #{border_color}; width: 1.5vw; height: 1.5vw; left: calc(#{x * 100}% - 0.75vw); top: calc(#{(1.0 - y) * 100}% - 0.75vw);"
  end

  defp station_position_style(_led), do: "display: none;"

  defp color_to_hex(color) do
    r = color.r |> Integer.to_string(16) |> String.pad_leading(2, "0")
    g = color.g |> Integer.to_string(16) |> String.pad_leading(2, "0")
    b = color.b |> Integer.to_string(16) |> String.pad_leading(2, "0")

    "##{r}#{g}#{b}"
  end
end
