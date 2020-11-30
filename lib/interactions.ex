defmodule ITKCommon.Interactions do
  @moduledoc """
  Handles interaction tracking.
  """
  alias ITKCommon.Thread
  alias ITKCommon.UserSessions

  @types ~w(event experiment)
  @from_session [
    "session_id",
    "app_version",
    "device_type",
    "mobile_app_version",
    "last_mobile_app",
    "os_version",
    "organization_uuid",
    "ip",
    "ip_location",
    "source_application"
  ]

  @doc """
  Captures an experiment.
  """
  @spec capture_experiment(data :: map, user_or_session_or_token :: any) :: :ok
  def capture_experiment(data, user_or_session_or_token) do
    capture("experiment", data, user_or_session_or_token)
  end

  @doc """
  Captures an event.
  """
  @spec capture_event(data :: map, user_or_session_or_token :: any) :: :ok
  def capture_event(data, user_or_session_or_token) do
    capture("event", data, user_or_session_or_token)
  end

  @doc """
  Captures an interaction.
  """
  @spec capture(type :: String.t(), data :: map, user_or_session_or_token :: any) :: :ok
  def capture(type, interaction_data = %{}, token) when is_nil(token) or token == "public" do
    session_data =
      Map.merge(
        Thread.to_map(),
        %{"role" => "student", "uuid" => "guest"}
      )

    capture(type, interaction_data, session_data)
  end

  def capture(type, interaction_data = %{}, token) when is_binary(token) do
    token
    |> UserSessions.get()
    |> case do
      {:ok, session_data} -> capture(type, interaction_data, session_data)
      _ -> :ok
    end
  end

  def capture(type, interaction_data = %{}, user = %{user_role: _}) do
    user
    |> UserSessions.latest_session()
    |> case do
      {:ok, session_data} -> capture(type, interaction_data, session_data)
      _ -> :ok
    end
  end

  def capture(type, interaction_data = %{}, session_data = %{})
      when is_map(session_data) and type in @types do
    payload =
      session_data
      |> prepare(interaction_data)
      |> Map.put("timestamp", ITKCommon.Utils.Text.iso8601_now())

    ITKQueue.publish("interaction.create", %{"type" => type, "payload" => payload})
  end

  def capture(_type, _payload, _any), do: :ok

  defp prepare(session_data, interaction_data) do
    session_data
    |> Map.take(@from_session)
    |> Map.put("user_uuid", session_data["uuid"])
    |> Map.put("user_role", session_data["role"])
    |> Map.merge(interaction_data)
    |> Map.put_new("session_id", Ecto.UUID.generate())
  end
end
