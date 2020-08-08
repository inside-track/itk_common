defmodule ITKCommon.Events do
  @moduledoc """
  Handles interactions with event tracking.
  """
  alias ITKCommon.UserSessions

  @from_session [
    "session_id",
    "app_version",
    "device_type",
    "mobile_app_version",
    "last_mobile_app",
    "os_version",
    "organization_uuid",
    "ip",
    "ip_location"
  ]

  @doc """
  Captures an event.
  """
  @spec capture(event_data :: map, user_or_session_or_token :: any) :: :ok
  def capture(event_data = %{}, token) when is_binary(token) or is_nil(token) do
    token
    |> UserSessions.get()
    |> case do
      {:ok, session_data} -> capture(event_data, session_data)
      _ -> capture(event_data, %{})
    end
  end

  def capture(event_data = %{}, user = %{uuid: _}) do
    user
    |> UserSessions.latest_session()
    |> case do
      {:ok, session_data} -> capture(event_data, session_data)
      _ -> capture(event_data, %{})
    end
  end

  def capture(event_data = %{}, session_data = %{}) when is_map(session_data) do
    payload =
      session_data
      |> prepare(event_data)
      |> Map.put("timestamp", ITKCommon.Utils.Text.iso8601_now())

    ITKQueue.publish("interaction.create", payload)
  end

  def capture(_payload, _any), do: :ok

  defp prepare(session_data, event_data) do
    session_data
    |> Map.take(@from_session)
    |> Map.put("user_uuid", session_data["uuid"])
    |> Map.put("user_role", session_data["role"])
    |> Map.merge(event_data)
  end
end
