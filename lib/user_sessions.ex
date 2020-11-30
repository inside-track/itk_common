require Logger

defmodule ITKCommon.UserSessions do
  @moduledoc """
  ITK Session tracking for authentication and events
  """

  defstruct [
    :uuid,
    :role,
    :organization_uuid,
    :token,
    :session_id,
    :app_version,
    :os_version,
    :device_type,
    :timestamp,
    :ip,
    :ip_location
  ]

  alias ITKCommon.OrganizationIdToUuid
  alias ITKCommon.Redis
  alias ITKCommon.Utils

  @type session ::
          %__MODULE__{
            uuid: String.t() | nil,
            role: String.t() | nil,
            organization_uuid: String.t() | nil,
            token: String.t() | nil,
            app_version: String.t() | nil,
            os_version: String.t() | nil,
            device_type: String.t() | nil,
            session_id: String.t() | nil,
            timestamp: String.t() | nil,
            ip: String.t() | nil,
            ip_location: String.t() | nil
          }
          | nil

  @type user :: map
  @typep not_found :: {:error, :not_found, String.t()}
  @typep session_success :: {:ok, map}
  @typep field_tracker :: {session :: session, old_session :: session, values :: map}
  @typep string_tuple :: {String.t(), String.t()}

  @auth_duration 31_556_952
  @auth_list_key_prefix "authentication:cache:tokens_by_user_uuid:"
  @last_active_prefix "last_active_by_user_uuid:"

  @accessible MapSet.new([
                "organization_uuid",
                "app_version",
                "os_version",
                "device_type",
                "session_id",
                "ip",
                "ip_location"
              ])

  @doc """
  start an ITK Session for `user` with `token`
  """
  @spec start(user :: user) :: String.t()
  def start(user) do
    start(user, nil, %{})
  end

  def start(user, metadata = %{}) do
    start(user, nil, metadata)
  end

  def start(user, token) do
    start(user, token, %{})
  end

  def start(user, token, metadata = %{}) do
    uuid =
      case user do
        %{itk_coach_uuid: uuid} -> uuid
        %{uuid: uuid} -> uuid
      end

    token = token || generate_token(uuid)

    %__MODULE__{
      uuid: uuid
    }
    |> restore_or_start(token, user, metadata)
    |> add_to_authlist(token)
    |> prune_authlist_async()

    token
  end

  @spec restore(token :: String.t(), metadata :: map) :: session_success | not_found
  def restore(token, metadata \\ %{}) do
    token
    |> get!()
    |> restore_or_start(token, nil, metadata)
    |> wrap()
  end

  @doc """
  deletes a session associated to `token`
  """
  @spec terminate(token :: String.t()) :: session_success | not_found
  def terminate(token) when is_binary(token) do
    token
    |> get!()
    |> add_token(token)
    |> delete()
    |> prune_authlist_async()
    |> wrap()
  end

  @spec terminate_all(user :: user) :: :ok
  def terminate_all(%{uuid: user_uuid}) when is_binary(user_uuid) do
    user_uuid
    |> tokens_by_user_uuid
    |> Enum.each(&Redis.delete/1)

    user_uuid
    |> auth_list_key
    |> Redis.delete()

    if Mix.env() in [:prod, :staging, :production] do
      Logger.info("Deauthorized User - UUID: #{user_uuid}")
    end

    :ok
  end

  @spec latest_session(user :: user) :: session_success | not_found
  def latest_session(user) do
    user
    |> latest_token
    |> get
  end

  @spec latest_token(user :: user) :: String.t()
  def latest_token(%{uuid: user_uuid}) do
    {:ok, token} =
      user_uuid
      |> auth_list_key()
      |> Redis.first()

    token
  end

  @doc """
  get a session, unlike restore/1 it does not have side effects
  """
  @spec get(token :: String.t() | nil) :: session_success | not_found
  def get(nil) do
    {:error, :not_found, "Session was not found."}
  end

  def get("public") do
    get(nil)
  end

  def get(token) do
    token
    |> get!
    |> wrap()
  end

  @spec generate_token(user_uuid :: String.t()) :: String.t()
  def generate_token(_user_uuid) do
    UUID.uuid4()
  end

  @spec tokens_by_user_uuid(user_uuid :: String.t()) :: list(String.t())
  def tokens_by_user_uuid(user_uuid) do
    user_uuid
    |> auth_list_key()
    |> Redis.get_list()
    |> case do
      {:ok, list} ->
        list

      _ ->
        []
    end
  end

  @spec by_user_uuid(user_uuid :: String.t()) :: list(session)
  def by_user_uuid(user_uuid) do
    user_uuid
    |> tokens_by_user_uuid
    |> Enum.reduce(%{}, fn token, acc ->
      case get!(token) do
        nil -> acc
        session -> Map.put(acc, token, session)
      end
    end)
  end

  @spec auth_list_key(user_uuid :: String.t()) :: String.t()
  def auth_list_key(user_uuid) do
    "#{@auth_list_key_prefix}:#{user_uuid}"
  end

  @spec prune_auth_list(user_uuid :: String.t()) :: :ok
  def prune_auth_list(user_uuid) do
    tokens =
      user_uuid
      |> tokens_by_user_uuid()
      |> Enum.filter(&Redis.exists?/1)

    user_uuid
    |> auth_list_key()
    |> replace_authlist(tokens)
  end

  defp prune_authlist_async(session = %{uuid: user_uuid}) do
    ITKCommon.do_async(__MODULE__, :prune_auth_list, [user_uuid])
    session
  end

  defp prune_authlist_async(session), do: session

  defp replace_authlist(key, []) do
    Redis.delete(key)
    :ok
  end

  defp replace_authlist(key, tokens) do
    Redis.multi([
      ["DEL", key],
      ["RPUSH" | [key | tokens]]
    ])

    :ok
  end

  @spec get!(token :: String.t()) :: session
  defp get!(token) do
    token
    |> Redis.get()
    |> case do
      {:ok, nil} ->
        nil

      {:ok, data} ->
        case Jason.decode(data) do
          {:ok, decoded} -> decoded
          _ -> nil
        end
    end
    |> to_session()
  end

  @spec get_last_active(user_uuid_list :: list(String.t())) :: list(string_tuple)
  def get_last_active([]), do: []

  def get_last_active(user_uuid_list) do
    {:ok, result} =
      user_uuid_list
      |> Enum.map(&get_last_active_key(&1))
      |> Redis.mget()

    Enum.zip(user_uuid_list, result)
  end

  defp get_last_active_key(uuid), do: @last_active_prefix <> uuid

  # this function modifies the session stored at `token`
  # when modifications are detected the storage is updated
  # this function also attempts to update profile fields
  # use get! (private) or get to retrieve session without these side effects
  @spec restore_or_start(
          session :: session,
          token :: String.t(),
          user :: user | nil,
          metadata :: map
        ) :: session
  defp restore_or_start(session, token, user, metadata) do
    session
    |> add_role(user)
    |> add_session_id()
    |> add_token(token)
    |> add_metadata(metadata)
    |> add_organization_uuid(user)
    |> add_timestamp()
    |> save()
    |> track_last_active()
    |> track_associated_fields(session)
  end

  @spec add_role(session :: session, user :: user | nil) :: session
  defp add_role(session, nil), do: session
  defp add_role(nil, _user), do: nil

  defp add_role(session, %{user_role: role}) do
    %{session | role: role}
  end

  defp add_metadata(nil, _), do: nil

  defp add_metadata(session, metadata) do
    metadata = clean_metadata(metadata)
    Map.merge(session, metadata)
  end

  defp add_organization_uuid(session = %{organization_uuid: nil, role: role}, %{
         organization_id: org_id
       })
       when role in ~w(student guest) do
    if OrganizationIdToUuid.configured?() do
      org_id
      |> OrganizationIdToUuid.get()
      |> case do
        nil ->
          session

        org_uuid ->
          %{session | organization_uuid: org_uuid}
      end
    else
      session
    end
  end

  defp add_organization_uuid(session, _), do: session

  @spec add_timestamp(session :: session) :: session
  defp add_timestamp(nil), do: nil

  defp add_timestamp(session) do
    %{session | timestamp: Utils.Text.iso8601_now()}
  end

  @spec add_token(session :: session, token :: String.t()) :: session
  defp add_token(session = %{token: nil}, token) do
    %{session | token: token}
  end

  defp add_token(session, _), do: session

  @spec add_session_id(session :: session) :: session
  defp add_session_id(session = %{session_id: nil}) do
    %{session | session_id: UUID.uuid4()}
  end

  defp add_session_id(session), do: session

  @spec save(session :: session) :: session
  defp save(session = %__MODULE__{}) do
    payload =
      session
      |> Map.from_struct()
      |> Jason.encode!()

    Redis.set(session.token, payload, @auth_duration)
    session
  end

  defp save(session), do: session

  @spec track_last_active(session :: session) :: session
  defp track_last_active(session = %__MODULE__{timestamp: timestamp, role: "coach", uuid: uuid}) do
    ITKCommon.do_async(fn ->
      uuid
      |> get_last_active_key()
      |> Redis.set(timestamp, @auth_duration)
    end)

    session
  end

  defp track_last_active(session), do: session

  @spec delete(session :: session) :: session
  defp delete(nil), do: nil

  defp delete(session) do
    Redis.delete(session.token)
    session
  end

  @spec to_map(session :: session) :: map | nil
  defp to_map(session = %__MODULE__{}) do
    %{
      "uuid" => session.uuid,
      "role" => session.role,
      "organization_uuid" => session.organization_uuid,
      "app_version" => session.app_version,
      "os_version" => session.os_version,
      "device_type" => session.device_type,
      "session_id" => session.session_id,
      "ip" => session.ip,
      "ip_location" => session.ip_location,
      "timestamp" => session.timestamp
    }
  end

  defp to_map(_), do: nil

  @spec wrap(session :: session) :: session_success | not_found
  defp wrap(session) do
    case to_map(session) do
      nil -> get(nil)
      map -> {:ok, map}
    end
  end

  @spec to_session(raw :: any) :: session
  defp to_session(raw) when is_map(raw) do
    Enum.reduce(raw, %__MODULE__{}, fn {k, v}, acc ->
      k =
        case k do
          "last_mobile_app" ->
            :device_type

          "mobile_app_version" ->
            :app_version

          other ->
            other
            |> to_string()
            |> String.to_atom()
        end

      if Map.has_key?(acc, k) do
        %{acc | k => v}
      else
        acc
      end
    end)
  end

  defp to_session(_), do: nil

  defp clean_metadata(data) do
    Enum.reduce(data, %{}, fn {k, v}, acc ->
      if not is_nil(v) and k in @accessible do
        Map.put(acc, String.to_atom(k), v)
      else
        acc
      end
    end)
  end

  defp add_to_authlist(session = %{uuid: uuid}, token) do
    key = auth_list_key(uuid)

    Redis.prepend(key, token)
    Redis.expire(key, @auth_duration)

    session
  end

  defp add_to_authlist(_, _), do: nil

  defp track_associated_fields(session = %{role: "student"}, session_old) do
    {session, session_old, %{}}
    |> track_last_app_session()
    |> track_device_type()
    |> track_app_version()
    |> publish_session_updates()

    session
  end

  defp track_associated_fields(session, _), do: session

  defp track_last_app_session({session, session_old = %{timestamp: old}, values}) do
    values =
      if is_nil(old) || Utils.Text.iso8601_now(minutes: -30) > old do
        Map.merge(values, %{
          "last_action_type" => "App Activity",
          "last_action_date" => Timex.now(),
          "last_app_session_date" => session.timestamp
        })
      else
        values
      end

    {session, session_old, values}
  end

  defp track_app_version(
         {session,
          session_old = %{
            app_version: old
          }, values}
       ) do
    values =
      if session.app_version == old || is_nil(session.app_version) do
        values
      else
        Map.put(values, "mobile_app_version", session.app_version)
      end

    {session, session_old, values}
  end

  @spec track_device_type(tracker :: field_tracker) :: field_tracker
  defp track_device_type(
         {session,
          session_old = %{
            device_type: old
          }, values}
       ) do
    values =
      if session.device_type == old || is_nil(session.device_type) do
        values
      else
        Map.put(values, "last_mobile_app", session.device_type)
      end

    {session, session_old, values}
  end

  defp publish_session_updates({session = %{role: "student"}, _, values}) do
    {_last_action_type, values} = Map.pop(values, "last_action_type")
    {last_action_date, values} = Map.pop(values, "last_action_date")
    publish_profile_update(session, values)
    publish_user_update(session, last_action_date)

    session
  end

  defp publish_session_updates({session, _, _}) do
    session
  end

  defp publish_profile_update(%{uuid: uuid, organization_uuid: org_uuid}, values)
       when not is_nil(org_uuid) and values != %{} do
    ITKQueue.publish(
      "student-profile.update",
      %{
        "student_uuid" => uuid,
        "organization_uuid" => org_uuid,
        "attributes" => values,
        "apply_superseded_filter" => false
      }
    )
  end

  defp publish_profile_update(_, _), do: :ok

  defp publish_user_update(_, nil), do: :ok

  defp publish_user_update(%{uuid: uuid}, last_action_date) do
    ITKQueue.publish(
      "user.update",
      %{
        "uuid" => uuid,
        "role" => "student",
        "last_app_activity" => last_action_date
      }
    )
  end
end
