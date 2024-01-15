defmodule MetarMap.AviationWeather do
  alias MetarMap.Metar

  #
  # API DOCUMENTATION: https://aviationweather.gov/data/api/#/Data/dataMetars
  #

  @base_url "https://aviationweather.gov/api/data/metar"
  @base_params %{format: "json"}

  def fetch_latest_metars(station_ids) do
    station_string = station_ids |> Enum.join(",")
    params = @base_params |> Map.put(:ids, station_string)

    case HTTPoison.get(@base_url, [], params: params) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, parse_metars(body)}

      {:ok, %HTTPoison.Response{} = response} ->
        {:error, response}

      {:error, error} ->
        {:error, error}
    end
  end

  defp parse_metars(body) do
    body
    |> Jason.decode!()
    |> Enum.map(fn json ->
      %{
        station_id: json["icaoId"],
        wind_speed_kt: json["wspd"],
        wind_gust_kt: json["wgst"],
        latitude: json["lat"],
        longitude: json["lon"],
        sky_conditions:
          Enum.map(json["clouds"], fn cloud ->
            %{
              cover: cloud["cover"],
              base_agl: cloud["base"]
            }
          end),
        visibility: parse_visibility(json["visib"])
      }
    end)
    |> Enum.map(&struct(Metar, &1))
    |> Enum.map(fn m -> Map.put(m, :category, Metar.get_category(m)) end)
  end

  defp parse_visibility(nil), do: nil
  defp parse_visibility("10+"), do: 10
  defp parse_visibility(int) when is_integer(int), do: int
  defp parse_visibility(float) when is_float(float), do: float
end
