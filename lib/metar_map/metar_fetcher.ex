defmodule MetarMap.MetarFetcher do
  use GenServer
  require Logger

  alias MetarMap.{AviationWeather, Metar, LedController, ConnectionWatcher}

  @poll_interval_ms 60_000
  @name __MODULE__

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def poll do
    send(@name, :poll)
  end

  @impl true
  def init(opts) do
    station_list = Keyword.fetch!(opts, :stations)
    station_ids = Enum.map(station_list, & &1.id)

    send(self(), :poll)

    VintageNet.subscribe(["interface", "wlan0", "connection"])

    {:ok, %{station_ids: station_ids, poll_ref: nil}}
  end

  @impl true
  def handle_info(
        {VintageNet, ["interface", "wlan0", "connection"], _old_value, new_value, _metadata},
        state
      ) do
    if new_value == :internet do
      Logger.info("[MetarFetcher] Internet connection established; polling now")
      Process.send_after(self(), :poll, 5_000)
    end

    {:noreply, state}
  end

  def handle_info(:poll, state) do
    if state.poll_ref do
      Process.cancel_timer(state.poll_ref)
    end

    state.station_ids
    |> AviationWeather.fetch_latest_metars()
    |> case do
      {:ok, metars} ->
        bounds = Metar.find_bounds(metars)

        fetched_station_ids =
          for metar <- metars do
            if LedController.exists?(metar.station_id) do
              LedController.put_metar(metar, bounds)
            else
              Logger.warn("[MetarFetcher] Fetched extra station: #{metar.station_id}")
            end

            metar.station_id
          end

        missing_ids = state.station_ids -- fetched_station_ids

        if !Enum.empty?(missing_ids) do
          Logger.warn("[MetarFetcher] Could not fetch: #{Enum.join(missing_ids, ", ")}")
        end

        ConnectionWatcher.put_fetch_ok(true)
        Logger.info("[MetarFetcher] Retrieved #{length(metars)} METARs")

      _ ->
        ConnectionWatcher.put_fetch_ok(false)
        Logger.warn("[MetarFetcher] Error fetching METARs")
    end

    poll_ref = Process.send_after(self(), :poll, @poll_interval_ms)

    {:noreply, %{state | poll_ref: poll_ref}}
  end
end
