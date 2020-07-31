defmodule ITKCommon.ZipGeolocation do
  @moduledoc """
  Module to handling zipcode to geopoint (latitude, longitude) mapping
  """

  alias ITKCommon.Redis

  @type error :: {:error, String.t()}
  @type success_geopoint :: {:ok, String.t()}
  @type success :: :ok

  @key "zip-geolocation-data"

  @doc """
  Get geolocation point by zipcode
  """
  @spec get(zipcode :: String.t()) :: error | success_geopoint
  def get(zipcode) do
    case check_and_truncate_zipcode(zipcode) do
      {:ok, truncated_zip} -> get_geopoint(truncated_zip)
      _ -> {:error, "Invalid zipcode format."}
    end
  end

  @doc """
  Key where the data is stored as hash
  """
  def key do
    @key
  end

  @doc """
  Function to load all geo locations points in redis and set `loaded` flag to true.
  calling this function should be async
  """
  @spec load(data :: map() | nil) :: success
  def load(data \\ nil) do
    data = data || load_data()

    Enum.each(data, fn {zipcode, geopoint} ->
      {:ok, _} = Redis.hsetnx(@key, zipcode, geopoint)
    end)

    {:ok, _} = Redis.hset(@key, "loaded", "true")

    :ok
  end

  def clear do
    Redis.delete(@key)
  end

  defp loaded?, do: Redis.hget(@key, "loaded") == {:ok, "true"}

  defp get_geopoint(truncated_zip) do
    if loaded?() do
      get_from_cache(truncated_zip)
    else
      get_from_file(truncated_zip)
    end
  end

  defp get_from_cache(truncated_zip) do
    with {:ok, geopoint} <- Redis.hget(@key, truncated_zip),
         false <- is_nil(geopoint) do
      {:ok, geopoint}
    else
      true -> {:error, "No geopoint match for this zipcode."}
    end
  end

  defp get_from_file(truncated_zip) do
    data = load_data()
    ITKCommon.do_async(__MODULE__, :load, [data])

    case data[truncated_zip] do
      nil -> {:error, "No geopoint match for this zipcode."}
      geopoint -> {:ok, geopoint}
    end
  end

  defp check_and_truncate_zipcode(zipcode) do
    # match zipcode (5 digits or 9 digits)
    with true <- Regex.match?(~r/^\d{5}$|^\d{9}$/, zipcode) do
      {:ok, String.slice(zipcode, 0..4)}
    end
  end

  defp load_data do
    read_file(load_path())
  end

  defp read_file(file_path) do
    with {:ok, io} <- File.open(file_path, [:read, :compressed]),
         data <- IO.read(io, :all) do
      Jason.decode!(data)
    else
      _ -> raise "Problem reading file"
    end
  end

  defp load_path do
    sub_dir =
      :itk
      |> Application.get_env(__MODULE__, Keyword.new())
      |> Keyword.get(:load_path, "geolocation")

    priv_dir = :itk_common |> :code.priv_dir() |> to_string

    Path.join([priv_dir, sub_dir, "zipcode.json.gz"])
  end
end
