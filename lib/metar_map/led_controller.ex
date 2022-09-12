defmodule MetarMap.LedController do
  use GenServer
  require Logger

  alias MetarMap.Display.Color
  alias MetarMap.{Display, Station, Timeline, Config}

  @registry __MODULE__.Registry

  @frame_interval_ms 40
  @flash_fade_duration_ms 500
  @fade_duration_ms 1_500
  @wipe_duration_ms 2_000
  @flash_interval_ms 3_000
  @flicker_probability 0.2
  @flicker_brightness 0.7

  @colors %{
    off: %Color{r: 0, g: 0, b: 0},
    red: %Color{r: 0xFF, g: 0, b: 0},
    orange: %Color{r: 0xFF, g: 0x80, b: 0},
    yellow: %Color{r: 0xFF, g: 0xFF, b: 0},
    green: %Color{r: 0, g: 0xFF, b: 0},
    blue: %Color{r: 0, g: 0, b: 0xFF},
    purple: %Color{r: 0xFF, g: 0, b: 0xFF},
    white: %Color{r: 0xFF, g: 0xFF, b: 0xFF}
  }

  defmodule State do
    defstruct [
      :station,
      :timeline,
      :prefs,
      :latest_color,
      :pixel,
      :flicker?,
      :display_mode,
      :frame_timer_ref,
      :flash_timer_ref
    ]
  end

  def start_link(%Station{} = station, prefs) do
    GenServer.start_link(__MODULE__, {station, prefs}, name: name(station.id))
  end

  def put_metar(metar, bounds) do
    metar.station_id |> name() |> GenServer.cast({:put_metar, metar, bounds})
  end

  def put_prefs(prefs) do
    Registry.dispatch(@registry, nil, fn entries ->
      for {pid, _id} <- entries do
        GenServer.cast(pid, {:put_prefs, prefs})
      end
    end)
  end

  def put_all_display_mode(mode) do
    Registry.dispatch(@registry, nil, fn entries ->
      Enum.each(entries, fn {pid, _id} ->
        GenServer.cast(pid, {:put_display_mode, mode})
      end)
    end)
  end

  def put_one_display_mode(mode) do
    Registry.dispatch(@registry, nil, fn
      [] ->
        :ok

      [{first, _id} | rest] ->
        GenServer.cast(first, {:put_display_mode, mode})

        Enum.each(rest, fn {pid, _id} ->
          GenServer.cast(pid, {:put_display_mode, :off})
        end)
    end)
  end

  def get_state(station_id) do
    station_id |> name() |> GenServer.call(:get_state)
  end

  def get_all_states do
    Config.stations()
    |> Enum.map(fn station ->
      Task.async(fn -> get_state(station.id) end)
    end)
    |> Task.await_many()
  end

  def exists?(id_or_station) do
    !is_nil(id_or_station |> name() |> Process.whereis())
  end

  defp name(%Station{id: id}), do: name(id)
  defp name(id) when is_binary(id), do: Module.concat([__MODULE__, id])

  def child_spec(opts) do
    station = Keyword.fetch!(opts, :station)
    prefs = Keyword.fetch!(opts, :prefs)

    %{
      id: name(station.id),
      start: {__MODULE__, :start_link, [station, prefs]}
    }
  end

  def init({station, prefs}) do
    {:ok, _} = Registry.register(@registry, nil, station.id)

    start_animation()

    {:ok,
     %State{
       station: station,
       prefs: prefs,
       timeline: Timeline.init(@colors.off, {MetarMap.Interpolation, :blend_colors}),
       pixel: {station.index, 0},
       display_mode: :off
     }}
  end

  def handle_call(:get_state, _, state), do: {:reply, state, state}

  def handle_cast({:put_metar, metar, bounds}, state) do
    next_station =
      state.station
      |> Station.put_metar(metar)
      |> put_station_position(metar, bounds)

    if Station.get_category(next_station) == :unknown do
      Logger.warn("[#{next_station.id}] Flight category unknown")
    end

    state = %State{state | station: next_station}

    state =
      if state.display_mode == :metar do
        start_animation()
        next_timeline = update_station_color(state.timeline, state)
        %State{state | timeline: next_timeline}
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:put_prefs, new_prefs}, state) do
    # If we change modes, fade out and then back in
    timeline =
      if new_prefs.mode != state.prefs.mode do
        state.timeline
        |> Timeline.abort()
        |> Timeline.append(@fade_duration_ms, @colors.off, min_delay_ms: wipe_delay_ms(state))
        |> Timeline.append(@fade_duration_ms, station_color(state.station, new_prefs.mode))
      else
        state.timeline
      end

    start_animation()

    {:noreply, %State{state | prefs: new_prefs, timeline: timeline}}
  end

  def handle_cast({:put_display_mode, display_mode}, state) do
    {:noreply, do_put_display_mode(state, display_mode)}
  end

  # Only kick off animations if we aren't already animating
  def handle_info(:start_animation, %{frame_timer_ref: nil} = state) do
    {:noreply, animate(state)}
  end

  def handle_info(:start_animation, state) do
    {:noreply, state}
  end

  def handle_info(:frame, state) do
    {:noreply, animate(state)}
  end

  def handle_info({:flash, color}, state) do
    timeline =
      state.timeline
      |> Timeline.append(@flash_fade_duration_ms, Map.fetch!(@colors, color))
      |> Timeline.append(@flash_fade_duration_ms, Map.fetch!(@colors, color))
      |> Timeline.append(@flash_fade_duration_ms, @colors.off)

    timer_ref = Process.send_after(self(), {:flash, color}, @flash_interval_ms)

    start_animation()

    {:noreply, %State{state | timeline: timeline, flash_timer_ref: timer_ref}}
  end

  def terminate(_, state) do
    Display.set_pixel(state.pixel, @colors.off)
  end

  defp animate(state) do
    is_flickering = is_windy?(state)

    # Kick off the next frame ASAP if necessary
    state =
      if is_flickering or !Timeline.empty?(state.timeline) do
        trigger_delayed_frame(state, @frame_interval_ms)
      else
        %State{state | frame_timer_ref: nil}
      end

    {color, timeline} = Timeline.evaluate(state.timeline)

    # Randomly toggle the flickering if it's windy
    next_flicker? =
      cond do
        !is_flickering -> false
        :rand.uniform() < @flicker_probability -> !state.flicker?
        true -> state.flicker?
      end

    # If flickering, dim it to 80%
    color = if next_flicker?, do: MetarMap.brighten(color, @flicker_brightness), else: color

    # For performance - only update if necessary
    if color != state.latest_color do
      Display.set_pixel(state.pixel, color)
    end

    %State{state | timeline: timeline, latest_color: color, flicker?: next_flicker?}
  end

  defp update_station_color(timeline, state, opts \\ []) do
    next_color = station_color(state.station, state.prefs.mode)

    if next_color != timeline.latest_value do
      delay_ms = Keyword.get(opts, :delay_ms, 0)
      duration_ms = Keyword.get(opts, :duration_ms, @fade_duration_ms)
      Timeline.append(timeline, duration_ms, next_color, min_delay_ms: delay_ms)
    else
      timeline
    end
  end

  @wind_speed_gradient [
    {5, @colors.green},
    {10, @colors.yellow},
    {25, @colors.red},
    {35, @colors.purple},
    {50, @colors.white}
  ]

  @ceiling_gradient [
    {1000, @colors.red},
    {3000, @colors.orange},
    {5000, @colors.yellow},
    {10000, @colors.green}
  ]

  @visiblity_gradient [
    {1, @colors.red},
    {3, @colors.orange},
    {5, @colors.yellow},
    {10, @colors.green}
  ]

  defp station_color(station, "flight_category") do
    station
    |> Station.get_category()
    |> case do
      :vfr -> @colors.green
      :mvfr -> @colors.blue
      :ifr -> @colors.red
      :lifr -> @colors.purple
      _ -> @colors.off
    end
  end

  defp station_color(station, "wind_speed") do
    MetarMap.blend_gradient(@wind_speed_gradient, Station.get_max_wind(station), @colors.off)
  end

  defp station_color(station, "ceiling") do
    MetarMap.blend_gradient(@ceiling_gradient, Station.get_ceiling(station), @colors.off)
  end

  defp station_color(station, "visibility") do
    MetarMap.blend_gradient(@visiblity_gradient, Station.get_visibility(station), @colors.off)
  end

  defp wipe_delay_ms(%{station: %{position: nil}}), do: 0

  defp wipe_delay_ms(%{station: %{position: {_x, y}}}) do
    # Wipe downwards, so invert y-axis
    trunc(@wipe_duration_ms * (1.0 - y))
  end

  defp put_station_position(
         %{position: nil} = station,
         metar,
         {{min_lat, max_lat}, {min_lon, max_lon}}
       ) do
    x_position = MetarMap.normalize(min_lon, max_lon, metar.longitude)
    y_position = MetarMap.normalize(min_lat, max_lat, metar.latitude)

    %Station{station | position: {x_position, y_position}}
  end

  defp put_station_position(station, _metar, _bounds), do: station

  defp is_windy?(state) do
    state.display_mode == :metar and
      state.prefs.max_wind_kts > 0 and
      Station.get_max_wind(state.station) >= state.prefs.max_wind_kts
  end

  defp start_animation do
    send(self(), :start_animation)
  end

  defp trigger_delayed_frame(state, delay_ms) do
    timer_ref = Process.send_after(self(), :frame, delay_ms)
    %State{state | frame_timer_ref: timer_ref}
  end

  defp do_put_display_mode(%{display_mode: display_mode} = state, display_mode), do: state

  defp do_put_display_mode(state, display_mode) do
    state = cancel_flash_timer(state)

    next_timeline =
      case display_mode do
        :off ->
          state.timeline
          |> Timeline.abort()
          |> Timeline.append(@fade_duration_ms, @colors.off)

        :metar ->
          state.timeline
          |> Timeline.abort()
          |> Timeline.append(@fade_duration_ms, @colors.off)
          |> update_station_color(state, delay_ms: wipe_delay_ms(state))

        {:flashing, _color} ->
          state.timeline
          |> Timeline.abort()
          |> Timeline.append(@fade_duration_ms, @colors.off)

        {:solid, color} ->
          state.timeline
          |> Timeline.abort()
          |> Timeline.append(@fade_duration_ms, @colors.off)
          |> Timeline.append(@fade_duration_ms, Map.fetch!(@colors, color))

        _else ->
          state.timeline
      end

    timer_ref =
      case display_mode do
        {:flashing, color} -> Process.send_after(self(), {:flash, color}, @flash_interval_ms)
        _else -> nil
      end

    start_animation()

    %State{
      state
      | display_mode: display_mode,
        timeline: next_timeline,
        flash_timer_ref: timer_ref
    }
  end

  defp cancel_flash_timer(state) do
    if state.flash_timer_ref do
      Process.cancel_timer(state.flash_timer_ref)
    end

    %State{state | flash_timer_ref: nil}
  end
end
