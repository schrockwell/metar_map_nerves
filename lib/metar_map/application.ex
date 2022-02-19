defmodule MetarMap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MetarMap.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: MetarMap.Worker.start_link(arg)
        # {MetarMap.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: MetarMap.Worker.start_link(arg)
      # {MetarMap.Worker, arg},
    ]
  end

  def children(_target) do
    # Children for all targets except host

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
      MetarMapWeb.Endpoint
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
end
