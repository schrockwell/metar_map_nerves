defmodule MetarMap.Tailscale do
  @moduledoc """
  Starting up the Tailscale VPN.
  """

  require Logger

  @doc """
  Returns true if the Tailscale VPN is enabled.
  """
  def enabled? do
    is_binary(auth_key())
  end

  @doc """
  Returns the child spec for various Tailscale processes.

  ## Arguments

    * `:modprobe` - The modprobe process that loads the `tun` kernel module
    * `:tailscaled` - The tailscaled process that manages the Tailscale VPN
    * `:tailscale` - The tailscale process that connects to the Tailscale VPN
  """
  def child_spec(:modprobe) do
    Supervisor.child_spec(
      {MuonTrap.Daemon, ["modprobe", ~w[tun], []]},
      id: :modprobe,
      restart: :transient
    )
  end

  def child_spec(:tailscaled) do
    path = Path.join([priv_dir(), "arm", "tailscaled"])

    args = ~w[
      --state=/data/tailscale/tailscaled.state
      --socket=/run/tailscale/tailscaled.sock
      --port=41641
    ]

    Supervisor.child_spec(
      {MuonTrap.Daemon, [path, args, []]},
      id: :tailscaled
    )
  end

  def child_spec(:tailscale) do
    path = Path.join([priv_dir(), "arm", "tailscale"])

    args = ~w[up --authkey #{auth_key()}]

    Supervisor.child_spec(
      {MuonTrap.Daemon, [path, args, []]},
      id: :tailscale,
      restart: :transient
    )
  end

  defp auth_key do
    Application.get_env(:metar_map, :tailscale_auth_key)
  end

  defp priv_dir, do: :metar_map |> :code.priv_dir() |> to_string()
end
