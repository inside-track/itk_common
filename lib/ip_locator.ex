defmodule ITKCommon.IpLocator do
  @moduledoc """
  Module to ip to country mapping for
  EG - Egypt
  RS - Serbia 
  US - United States
    PR - Puerto Rico
    MP - Northern Mariana Islands
    UM - Minor Islands
    AS - American Samoa
    GU - Guam
    VI - US Virgin Islands

    This module works by loading csv files formatted as such

    start,end,code
    1.0.0.0,1.0.1.1,ZZ
    1.1.1.1,2.2.2.2,XX
    3.0.0.0,3.3.3.3,YY

    OR with integer ranges

    start_int,end_int,code
    16777216,16777473,ZZ
    16843009,33686018,XX
    50331648,50529027,YY

    In the event the Redis store is initialized on a request
    the process will be spawned to load the data for subsequent requests.
    The current request will be allowed.

    The data is loaded to Redis using the Z* family of commands.
    To illustrate, the above example will produce the following Z entries

    4294967296  []
    50529027    [50331648,50529027,"YY"]
    33686018    [16843009,33686018,"XX"]
    16777473    [16777216,16777473,"ZZ"]

    The member value (i.e. [50331648,50529027,"YY"]) is a serialized json array representing the file data.
    This data arrangement works on the concept that each entry's score is the upper limit of IP range
    We pad our ranges with 4294967296 which is one greater than the limit for IPv4.
    This not only ensures we can detect total initialization but covers the entire IPv4 range.
    Partial initializations are effective only when the data file is sorted ASC.
    Using the command ZRANGEBYSCORE searches ranges with a given target_ip by:
    WHERE target_ip < UPPERLIMIT < 4294967296 ORDER ASC LIMIT 1

    Example 1 (request with uninitialized store):
      We receive a request with target ip 2.1.1.1
      Our redis store is not initialized
      We spawn a child process to initialize the store in Redis.
      We do not attempt to detect the IP location
      Return {:ok, "ALLOW"}

    Example 2 (request with partially initialized store):
      We receive a request with target ip 2.1.1.1
      Our redis store is initialized
      We derive integer 33620225
      Using ZRANGEBYSCORE we logically perform on our store:
        GET member WHERE 33620225 <= UPPERLIMIT <= 4294967296 ORDER ASC LIMIT 1
        Yielding "[16843009,33686018,"XX"]".
      We decode the json and compare the range as:
        33620225 in 16843009..33686018
        Yields true
      Return {:ok, "XX"}
    
    Example 3 (request with initialized store and a target within preset range):
      We receive a request with target ip 2.1.1.1
      Our redis store is being initialized
      We have a sorted data file and our loaded ranges has exceeded our target
      Our example will work identical to Example 2
      Return {:ok, "XX"}

    Example 4 (request with initialized store and a target not in preset range):
      We receive a request with target ip 2.3.1.1
      Our redis store is initialized
      We derive integer 33751297
      Using ZRANGEBYSCORE we logically perform on our store:
        GET member WHERE 33751297 <= UPPERLIMIT <= 4294967296 ORDER ASC LIMIT 1
        Yielding "[50331648,50529027,"YY"]".
      We decode the json and compare the range as:
        33620225 in 50331648..50529027
        Yields false
      Return {:ok, "INVALID"} or {:ok, "ALLOW"} depending on configuration
  """
  use Bitwise

  alias ITKCommon.Redis

  @type error :: {:error, atom}
  @type success_country :: {:ok, String.t()}

  @key "itk-ip-list"
  @max 4_294_967_296
  @allow "ALLOW"
  @invalid "INVALID"

  @doc """
  Get Country Code point by ip
  """
  @spec locate(ip :: any) :: success_country | error
  def locate(ip = {_, _, _, _}) do
    ip
    |> ip_to_integer()
    |> get_country()
  end

  def locate(ip) when is_binary(ip) do
    ip
    |> ip_to_tuple()
    |> locate()
  end

  def locate(_), do: {:error, :invalid_ip}

  @spec key :: String.t()
  def key do
    @key
  end

  @spec clear :: {:ok, integer}
  def clear do
    Redis.delete(@key)
  end

  @spec load :: :ok
  def load do
    load_path()
    |> File.stream!([:compressed])
    |> CSV.decode!(strip_fields: true, headers: true)
    |> Enum.each(fn row ->
      row
      |> add_entry()
      |> case do
        :ok -> :ok
        other -> raise other
      end
    end)

    zadd(@max, "[]")

    :ok
  end

  @doc """
  Use this function to change gap value.
  If we are blocking IPs this will allow
  running application to change its behavior.
  """
  @spec allow_all :: :ok | no_return | error
  def allow_all do
    Application.put_env(:itk_common, :itk_ip_list_gap, @allow)
    load()
  end

  @doc """
  Use this function to change gap value.
  If we are not blocking IPs this will allow
  running application to change its behavior.
  """
  @spec block_invalid :: :ok | no_return | error
  def block_invalid do
    Application.put_env(:itk_common, :itk_ip_list_gap, @invalid)
    load()
  end

  @spec default :: String.t()
  def default do
    Application.get_env(:itk_common, :itk_ip_list_gap, @invalid)
  end

  @spec allow :: String.t()
  def allow do
    @allow
  end

  @spec invalid :: String.t()
  def invalid do
    @invalid
  end

  defp get_country({:ok, int}) do
    int
    |> from_redis()
    |> case do
      {:ok, []} ->
        Task.start(__MODULE__, :load, [])
        {:ok, @allow}

      {:ok, [range]} ->
        from_range(range, int)

      other ->
        other
    end
  end

  defp get_country(tup), do: tup

  defp from_redis(int) do
    Redis.command(["ZRANGEBYSCORE", @key, int, @max, "LIMIT", 0, 1])
  end

  defp from_range(json, int) when is_binary(json) do
    with {:ok, range} <- Jason.decode(json) do
      from_range(range, int)
    else
      _ -> {:error, :invalid_data}
    end
  end

  defp from_range([min, max, code], int) when int in min..max do
    {:ok, code}
  end

  defp from_range(_range, _int) do
    {:ok, default()}
  end

  defp ip_to_integer({o1, o2, o3, o4}) do
    result =
      (o1 <<< 24) +
        (o2 <<< 16) +
        (o3 <<< 8) +
        o4

    if result >= @max do
      locate(nil)
    else
      {:ok, round(result)}
    end
  end

  defp ip_to_integer(ip) when is_binary(ip) do
    ip
    |> ip_to_tuple()
    |> ip_to_integer()
  end

  defp ip_to_tuple(ip) do
    ip
    |> String.trim()
    |> to_charlist()
    |> :inet.parse_ipv4_address()
    |> case do
      {:error, _} -> nil
      {:ok, tup} -> tup
    end
  end

  defp add_entry(%{"start_int" => s, "end_int" => e, "code" => c}) do
    with {:ok, json} <- Jason.encode([s, e, c]) do
      zadd(e, json)
      :ok
    end
  end

  defp add_entry(data = %{"start" => s, "end" => e}) do
    with {:ok, s_int} <- ip_to_integer(s),
         {:ok, e_int} <- ip_to_integer(e) do
      data
      |> Map.put("start_int", s_int)
      |> Map.put("end_int", e_int)
      |> add_entry()

      :ok
    end
  end

  defp data_directory do
    priv_dir = :itk_common |> :code.priv_dir() |> to_string

    :itk_common
    |> Application.get_env(:ip_locator, [])
    |> Keyword.get(:data_directory, priv_dir)
  end

  defp load_path do
    Path.join([data_directory(), "ip_locator", "ips.csv.gz"])
  end

  defp zadd(ip, json) do
    Redis.command(["ZADD", @key, ip, json])
  end
end
