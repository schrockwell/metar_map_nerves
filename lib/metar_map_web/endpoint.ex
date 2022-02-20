defmodule MetarMapWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :metar_map

  @session_options [
    store: :cookie,
    key: "_metar_map_key",
    signing_salt: "6zRp7XKI"
  ]

  socket "/socket", MetarMapWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :metar_map,
    gzip: false,
    only: ~w(assets css fonts images js favicon.ico robots.txt)

  plug Plug.RequestId
  plug Plug.Logger

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :learn_heex
  end

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  plug MetarMapWeb.Router
end
