defmodule ITKCommon.ZipGeolocation do
  @moduledoc """
  Module to handling zipcode to geopoint (latitude, longitude) mapping
  """

  use ITKCommon.RedisCache

  @type error :: {:error, String.t()}
  @type success_geopoint :: {:ok, String.t()}
  @type success :: :ok

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
    cache_name()
  end

  @doc """
  Function to load all geo locations points in redis and set `loaded` flag to true.
  calling this function should be async
  """
  @spec load(data :: map() | nil) :: success
  def load(data \\ nil) do
    data = data || load_data()

    Enum.each(data, fn {zipcode, geopoint} ->
      redis_set(zipcode, geopoint)
    end)

    redis_set("loaded", "true")

    :ok
  end

  def clear do
    redis_clear()
  end

  defp loaded?, do: redis_get("loaded") == "true"

  defp get_geopoint(truncated_zip) do
    if loaded?() do
      get_from_cache(truncated_zip)
    else
      get_from_file(truncated_zip)
    end
  end

  defp get_from_cache(truncated_zip) do
    case redis_get(truncated_zip) do
      nil ->
        {:error, "No geopoint match for this zipcode."}

      geopoint ->
        {:ok, geopoint}
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

  defp data_directory do
    priv_dir = :itk_common |> :code.priv_dir() |> to_string

    :itk_common
    |> Application.get_env(:ip_locator, [])
    |> Keyword.get(:data_directory, priv_dir)
  end

  defp load_path do
    Path.join([data_directory(), "zip_geolocation", "zipcode.json.gz"])
  end
end
