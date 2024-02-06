defmodule MetarMap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  alias MetarMap.Tailscale

  @supervisor MetarMap.Supervisor

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: @supervisor]

    prefs = MetarMap.Preferences.load()
    stations = MetarMap.Config.stations()
    ldr_pin = MetarMap.Config.ldr_pin()

    children =
      List.flatten([
        {Phoenix.PubSub, [name: MetarMap.PubSub, adapter: Phoenix.PubSub.PG2]},
        {Registry, keys: :duplicate, name: MetarMap.LedController.Registry},
        Enum.map(stations, &{MetarMap.LedController, station: &1, prefs: prefs}),
        {MetarMap.StripController, prefs: prefs},

        # This has to be before ConnectionWatcher
        MetarMapWeb.Endpoint,

        # This has to be after the Endpoint
        MetarMap.ConnectionWatcher,

        # This has to be after ConnectionWatcher
        {MetarMap.MetarFetcher, stations: stations},
        if(ldr_pin, do: [{MetarMap.LdrSensor, gpio_pin: ldr_pin}], else: [])
      ]) ++ surprise_children(target())

    Supervisor.start_link(children, opts)
  end

  defp surprise_children(:rpi3a_tailscale) do
    if Tailscale.enabled?() do
      [
        {Tailscale, :modprobe},
        {Tailscale, :tailscaled},
        {Tailscale, :tailscale}
      ]
    else
      []
    end
  end

  defp surprise_children(_other) do
    []
  end

  def target do
    Application.get_env(:metar_map, :target)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MetarMapWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def start_endpoint do
    Supervisor.start_child(@supervisor, MetarMapWeb.Endpoint)
  end

  def stop_endpoint do
    Supervisor.terminate_child(@supervisor, MetarMapWeb.Endpoint)
  end
end
