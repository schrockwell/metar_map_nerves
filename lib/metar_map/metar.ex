defmodule MetarMap.Metar do
  defstruct [
    :station_id,
    :category,
    :wind_speed_kt,
    :wind_gust_kt,
    :wind_dir_degrees,
    :latitude,
    :longitude,
    :sky_conditions,
    :visibility
  ]

  @doc """
  Returns `{{min_lat, max_lat}, {min_lon, max_lon}}`
  """
  def find_bounds([first_metar | _] = metars) do
    initial_acc =
      {{first_metar.latitude, first_metar.latitude},
       {first_metar.longitude, first_metar.longitude}}

    Enum.reduce(metars, initial_acc, fn metar, {{min_lat, max_lat}, {min_lon, max_lon}} ->
      {
        {min(min_lat, metar.latitude), max(max_lat, metar.latitude)},
        {min(min_lon, metar.longitude), max(max_lon, metar.longitude)}
      }
    end)
  end

  def get_ceiling(%__MODULE__{sky_conditions: sky_conditions}) do
    sky_conditions
    |> Enum.sort_by(& &1.base_agl)
    |> Enum.find(&(&1.cover in ["BKN", "OVC"]))
    |> case do
      nil -> nil
      %{base_agl: base_agl} -> base_agl
    end
  end

  def get_category(%__MODULE__{} = metar) do
    ceiling = get_ceiling(metar)
    visibility = metar.visibility

    cond do
      is_nil(visibility) -> :unknown
      is_integer(ceiling) and (ceiling <= 500 or visibility <= 1) -> :lifr
      is_integer(ceiling) and (ceiling <= 1000 or visibility <= 3) -> :ifr
      is_integer(ceiling) and (ceiling <= 3000 or visibility <= 5) -> :mvfr
      true -> :vfr
    end
  end
end
