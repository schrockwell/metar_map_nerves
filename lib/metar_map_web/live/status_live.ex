defmodule MetarMapWeb.StatusLive do
  use MetarMapWeb, :live_view

  alias MetarMap.LdrSensor
  alias MetarMap.LedController
  alias MetarMap.Station

  @ldr_interval 1_000
  @leds_interval 60_000

  def mount(_, _, socket) do
    socket =
      socket
      |> assign_ldr()
      |> assign_leds()

    Process.send_after(self(), :read_ldr, @ldr_interval)
    Process.send_after(self(), :read_leds, @leds_interval)

    {:ok, socket}
  end

  def handle_info(:read_ldr, socket) do
    Process.send_after(self(), :read_ldr, @ldr_interval)
    {:noreply, assign_ldr(socket)}
  end

  def handle_info(:read_leds, socket) do
    Process.send_after(self(), :read_leds, @leds_interval)
    {:noreply, assign_leds(socket)}
  end

  defp assign_ldr(socket) do
    if LdrSensor.available?() do
      assign(socket, :ldr, LdrSensor.read())
    else
      assign(socket, :ldr, "N/A")
    end
  end

  defp assign_leds(socket) do
    leds = LedController.get_all_states() |> Enum.sort_by(& &1.station.id)
    assign(socket, :leds, leds)
  end

  defp station_position_style(%Station{position: {x, y}}) do
    "left: #{x * 100}%; top: #{(1.0 - y) * 100}%;"
  end
end
