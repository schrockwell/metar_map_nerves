defmodule MetarMap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  alias MetarMap.LedController

  @supervisor MetarMap.Supervisor

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: @supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: MetarMap.Worker.start_link(arg)
        # {MetarMap.Worker, arg},
      ] ++ children(target())

    with {:ok, sup} <- Supervisor.start_link(children, opts) do
      maybe_start_wifi_wizard()
      {:ok, sup}
    end
  end

  def children(_target) do
    # Children for all targets, including host

    prefs = MetarMap.Preferences.load()
    stations = MetarMap.Config.stations()
    ldr_pin = MetarMap.Config.ldr_pin()

    # List all child processes to be supervised
    List.flatten([
      {Registry, keys: :duplicate, name: MetarMap.LedController.Registry},
      Enum.map(stations, &{MetarMap.LedController, station: &1, prefs: prefs}),
      {MetarMap.StripController, prefs: prefs},
      {MetarMap.MetarFetcher, stations: stations},
      if(ldr_pin, do: [{MetarMap.LdrSensor, gpio_pin: ldr_pin}], else: []),
      {Phoenix.PubSub, [name: MetarMap.PubSub, adapter: Phoenix.PubSub.PG2]}
      # MetarMapWeb.Endpoint
    ])
  end

  def target() do
    Application.get_env(:metar_map, :target)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MetarMapWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp maybe_start_wifi_wizard do
    case VintageNetWizard.run_if_unconfigured(on_exit: {__MODULE__, :handle_on_exit, []}) do
      :ok ->
        Logger.info("WiFi not configured; launching wizard")
        LedController.put_one_display_mode({:flashing, :purple})

      :configured ->
        Logger.info("WiFi already configured; starting Phoenix")
        LedController.put_one_display_mode({:flashing, :green})
        start_endpoint()

      {:error, message} ->
        Logger.warn("Error starting VintageNetWizard: #{message}")
        start_endpoint()
    end
  end

  def handle_on_exit do
    Logger.info("WiFi wizard exited; starting Phoenix now")
    LedController.put_one_display_mode({:flashing, :green})
    start_endpoint()
  end

  defp start_endpoint do
    Supervisor.start_child(@supervisor, MetarMapWeb.Endpoint)
  end
end
