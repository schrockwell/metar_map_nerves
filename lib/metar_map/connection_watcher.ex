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
        wifi_configured?: false,
        wifi_reset_gpio: open_wifi_reset_gpio(),
        connection_status: :disconnected,
        fetch_failures: 0,
        fetch_successes: 0,
        simulate: nil
      }
      |> put_wifi_configured()
      |> put_connection_status(VintageNet.get(@connection_property))
      |> handle_new_status()

    {:ok, state}
  end

  defp open_wifi_reset_gpio do
    if wifi_reset_pin = Application.get_env(:metar_map, :wifi_reset_pin) do
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

  def handle_info(:wizard_exit, state) do
    {:noreply,
     state
     |> put_wifi_configured()
     |> handle_new_status()}
  end

  def handle_info({:circuits_gpio, _pin, _timestamp, 0}, state) do
    # Rudimentary debounce: only transition on the first falling edge
    if state.wifi_configured? do
      {:noreply, %{state | wifi_configured?: false} |> handle_new_status()}
    else
      {:noreply, state}
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

  defp put_wifi_configured(state) do
    %{state | wifi_configured?: VintageNetWizard.wifi_configured?(@interface)}
  end

  defp overall_status(state) do
    cond do
      state.simulate -> state.simulate
      not state.wifi_configured? -> :wizarding
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
    # The wizard has already exited, so we don't need to explicitly stop it here
    MetarMap.Application.start_endpoint()
    state
  end

  defp handle_transition(state, :to, :wizarding) do
    MetarMap.Application.stop_endpoint()
    VintageNetWizard.run_wizard(on_exit: {__MODULE__, :handle_on_wizard_exit, [self()]})
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

  def handle_on_wizard_exit(pid) do
    # Wait a bit for the wizard to exit so that the the wifi can be reconfigured
    Process.send_after(pid, :wizard_exit, 5_000)
  end
end
