defmodule ITKCommon.HeaderParser do
  @moduledoc """
  A plug for parsing headers for key/values ITK is concerned with.
  """

  import Plug.Conn

  alias ITKCommon.IpLocator
  alias ITKCommon.Thread

  def init(options), do: options

  def call(conn) do
    conn
    |> add_itk_meta()
    |> add_header_value("app-version", "app_version")
    |> add_header_value("os-version", "os_version")
    |> add_device_type()
    |> add_token_value()
    |> add_ip()
  end

  defp add_header_value(conn, name, key) do
    conn
    |> get_header_value(name)
    |> put_into(key)

    conn
  end

  defp add_device_type(conn) do
    conn
    |> get_header_value("user-agent")
    |> detect_current_device()
    |> put_into("device_type")

    conn
  end

  defp add_token_value(conn) do
    conn
    |> credentials()
    |> case do
      creds when is_list(creds) ->
        put_into(creds, "credentials")

      creds ->
        put_into(creds, "access_token")
    end

    conn
  end

  defp add_ip(conn) do
    ip = RemoteIp.from(conn.req_headers, [])

    put_into(ip_to_string(ip), "ip")

    ip
    |> IpLocator.locate()
    |> case do
      {:ok, code} -> put_into(code, "ip_location")
      {:error, :invalid_ip} -> put_into(IpLocator.default(), "ip_location")
      _ -> put_into(IpLocator.allow(), "ip_location")
    end

    conn
  end

  @spec get_header_value(conn :: Plug.Conn.t(), name :: String.t()) :: String.t() | nil
  defp get_header_value(conn, name) do
    conn
    |> get_req_header(name)
    |> List.first()
  end

  @spec detect_current_device(user_agent :: any) :: String.t() | nil
  defp detect_current_device(user_agent) when is_binary(user_agent) do
    cond do
      String.match?(user_agent, ~r/Android|android/) ->
        "Android"

      String.match?(user_agent, ~r/iOS|iPhone|iPod|iPad|CFNetwork|logrado/) ->
        "iOS"

      true ->
        user_agent
    end
  end

  defp detect_current_device(_user_agent), do: nil

  defp ip_to_string(ip = {_, _, _, _}) do
    case :inet.ntoa(ip) do
      charlist when is_list(charlist) ->
        to_string(charlist)

      _ ->
        nil
    end
  end

  defp ip_to_string(_), do: nil

  defp put_into(data, key) do
    Thread.put(key, data)
  end

  defp credentials(conn) do
    conn
    |> get_req_header("authorization")
    |> parse_auth_header()
  end

  defp parse_auth_header(["Basic " <> hash]) do
    with {:ok, credentials} <- hash |> String.trim("\"") |> Base.decode64() do
      String.split(credentials, ":")
    end
  end

  defp parse_auth_header(["Token token=" <> token]) do
    String.replace(token, "\"", "")
  end

  defp parse_auth_header(_), do: :error

  defp add_itk_meta(conn = %{req_headers: headers}) do
    Enum.each(headers, fn {key, data} ->
      if Regex.match?(~r/^itk-meta-/i, key) do
        put_into(data, normalize_key(key))
      end
    end)

    conn
  end

  defp normalize_key(key) do
    key
    |> String.downcase()
    |> String.replace_prefix("itk-meta-", "")
    |> String.replace("-", "_")
    |> String.replace(~r/[^a-z0-9_]/, "")
  end
end
