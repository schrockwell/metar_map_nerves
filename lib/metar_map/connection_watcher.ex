defmodule MetarMap.ConnectionWatcher do
  use GenServer

  require Logger

  alias Circuits.GPIO
  alias MetarMap.LedController

  @interface "wlan0"
  @connection_property ["interface", @interface, "connection"]

  @display_modes %{
    new: {:flashing, :green},
    wizarding: {:flashing, :purple},
    no_internet_connection: {:flashing, :red},
    no_data: {:flashing, :blue},
    ok: :metar
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put_fetch_ok(fetch_ok) do
    GenServer.cast(__MODULE__, {:put_fetch_ok, fetch_ok})
  end

  def simulate(connection_status) do
    GenServer.cast(__MODULE__, {:simulate, connection_status})
  end

  def init(_) do
    VintageNet.subscribe(@connection_property)

    # Must come BEFORE handle_new_status/1 so we don't overwrite whatever it sets
    LedController.put_one_display_mode(@display_modes.new)

    state =
      %{
        status: :new,
        wizard_running?: false,
        # Need to hold onto this handle for... some reason? To prevent garbage collection?
        wifi_reset_gpio: open_wifi_reset_gpio(),
        connection_status: :disconnected,
        fetch_failures: 0,
        fetch_successes: 0,
        simulate: nil
      }
      |> put_connection_status(VintageNet.get(@connection_property))
      |> handle_new_status()

    {:ok, state}
  end

  defp open_wifi_reset_gpio do
    if wifi_reset_pin = Application.get_env(:metar_map, :wifi_reset_pin) do
      Logger.info("[ConnectionWatcher] Opening GPIO for WiFi reset (pin #{wifi_reset_pin})")
      {:ok, gpio} = GPIO.open(wifi_reset_pin, :input)
      :ok = GPIO.set_pull_mode(gpio, :pullup)
      :ok = GPIO.set_interrupts(gpio, :falling)
      gpio
    end
  end

  def handle_info({VintageNet, @connection_property, _old_value, new_value, _metadata}, state) do
    {:noreply,
     state
     |> put_connection_status(new_value)
     |> handle_new_status()}
  end

  def handle_info(:wizard_exited, state) do
    Logger.info("[ConnectionWatcher] Wizard exited")

    {:noreply,
     state
     |> put_wizard_running(false)
     |> handle_new_status()}
  end

  def handle_info({:circuits_gpio, _pin, _timestamp, 0}, state) do
    # Rudimentary debounce: only transition on the first falling edge
    if state.wizard_running? do
      Logger.info("[ConnectionWatcher] Wizard button pressed, but wizard already running")
      {:noreply, state}
    else
      Logger.info("[ConnectionWatcher] Wizard button pressed")
      {:noreply, state |> put_wizard_running(true) |> handle_new_status()}
    end
  end

  def handle_cast({:put_fetch_ok, true}, state) do
    {:noreply,
     %{state | fetch_failures: 0, fetch_successes: state.fetch_successes + 1}
     |> handle_new_status()}
  end

  def handle_cast({:put_fetch_ok, false}, state) do
    {:noreply,
     %{state | fetch_failures: state.fetch_failures + 1, fetch_successes: 0}
     |> handle_new_status()}
  end

  def handle_cast({:simulate, connection_status}, state) do
    {:noreply, %{state | simulate: connection_status} |> handle_new_status()}
  end

  defp put_connection_status(state, connection_status) do
    %{state | connection_status: connection_status}
  end

  defp put_wizard_running(state, running) do
    %{state | wizard_running?: running}
  end

  defp overall_status(state) do
    cond do
      state.simulate -> state.simulate
      state.wizard_running? -> :wizarding
      state.connection_status != :internet -> :no_internet_connection
      state.status == :new and state.fetch_successes == 0 and state.fetch_failures < 2 -> :new
      state.fetch_failures >= 2 -> :no_data
      :else -> :ok
    end
  end

  defp handle_new_status(state) do
    new_status = overall_status(state)

    if new_status == state.status do
      state
    else
      Logger.info(
        "[ConnectionWatcher] Transitioning from #{inspect(state.status)} to #{inspect(new_status)}"
      )

      state
      |> handle_transition(:from, state.status)
      |> handle_transition(:to, new_status)
      |> Map.put(:status, new_status)
    end
  end

  defp handle_transition(state, :from, :wizarding) do
    MetarMap.Application.start_endpoint()
    state
  end

  defp handle_transition(state, :to, :wizarding) do
    MetarMap.Application.stop_endpoint()
    VintageNetWizard.run_wizard(on_exit: {Kernel, :send, [self(), :wizard_exited]})
    LedController.put_one_display_mode(@display_modes.wizarding)
    state
  end

  defp handle_transition(state, :to, :no_internet_connection) do
    LedController.put_one_display_mode(@display_modes.no_internet_connection)
    state
  end

  defp handle_transition(state, :to, :no_data) do
    LedController.put_one_display_mode(@display_modes.no_data)
    state
  end

  defp handle_transition(state, :to, :ok) do
    LedController.put_all_display_mode(@display_modes.ok)
    state
  end

  defp handle_transition(state, _direction, _status), do: state
end
