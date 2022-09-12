defmodule MetarMap.ConnectionWatcher do
  use GenServer

  require Logger

  alias MetarMap.LedController

  @interface "wlan0"
  @connection_info ["interface", "wlan0", "connection"]

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put_fetch_ok(fetch_ok) do
    GenServer.cast(__MODULE__, {:put_fetch_ok, fetch_ok})
  end

  def init(_) do
    VintageNet.subscribe(@connection_info)

    state =
      %{
        status: :new,
        wifi_configured?: false,
        connection_status: :disconnected,
        fetch_failures: 0
      }
      |> put_wifi_configured()
      |> put_connection_status(VintageNet.get(@connection_info))
      |> handle_new_status()

    {:ok, state}
  end

  def handle_info({VintageNet, @connection_info, _old_value, new_value, _metadata}, state) do
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

  def handle_cast({:put_fetch_ok, true}, state) do
    {:noreply, %{state | fetch_failures: 0} |> handle_new_status()}
  end

  def handle_cast({:put_fetch_ok, false}, state) do
    {:noreply, %{state | fetch_failures: state.fetch_failures + 1} |> handle_new_status()}
  end

  defp put_connection_status(state, connection_status) do
    %{state | connection_status: connection_status}
  end

  defp put_wifi_configured(state) do
    %{state | wifi_configured?: VintageNetWizard.wifi_configured?(@interface)}
  end

  defp overall_status(state) do
    cond do
      not state.wifi_configured? -> :no_wifi_config
      state.connection_status != :internet -> :no_internet_connection
      state.fetch_failures < 2 -> :ok
      :else -> :no_data
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

  defp handle_transition(state, :from, :no_wifi_config) do
    VintageNetWizard.stop_wizard()
    MetarMap.Application.start_endpoint()
    state
  end

  defp handle_transition(state, :to, :no_wifi_config) do
    MetarMap.Application.stop_endpoint()
    VintageNetWizard.run_wizard(on_exit: {__MODULE__, :handle_on_wizard_exit, [self()]})
    LedController.put_one_display_mode({:flashing, :purple})
    state
  end

  defp handle_transition(state, :to, :no_internet_connection) do
    LedController.put_one_display_mode({:flashing, :red})
    state
  end

  defp handle_transition(state, :to, :no_data) do
    LedController.put_one_display_mode({:flashing, :blue})
    state
  end

  defp handle_transition(state, :to, :ok) do
    LedController.put_all_display_mode(:metar)
    state
  end

  defp handle_transition(state, _direction, _status), do: state

  def handle_on_wizard_exit(pid) do
    send(pid, :wizard_exit)
  end
end
