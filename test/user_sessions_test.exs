defmodule ITKCommon.UserSessionsTest do
  use ExUnit.Case

  alias ITKCommon.UserSessions
  alias ITKCommon.Redis
  alias ITKCommon.Utils.Text

  setup_all do
    clear_sessions()
  end

  describe "start/2" do
    test "stores a new session for student" do
      organization_uuid = UUID.uuid4()
      uuid = UUID.uuid4()
      student = %{user_role: "student", uuid: uuid}

      token = UserSessions.start(student, %{"organization_uuid" => organization_uuid})
      {:ok, session} = Redis.get(token)

      assert %{
               "uuid" => ^uuid,
               "role" => "student",
               "organization_uuid" => ^organization_uuid,
               "token" => ^token,
               "session_id" => _,
               "timestamp" => _
             } = Jason.decode!(session)

      assert_received [
        :publish,
        "student-profile.update",
        %{
          "attributes" => %{"last_app_session_date" => _},
          "organization_uuid" => ^organization_uuid,
          "student_uuid" => ^uuid
        }
      ]

      assert_received [
        :publish,
        "user.update",
        %{
          "last_app_activity" => _,
          "uuid" => ^uuid
        }
      ]
    end

    test "stores a new session for a coach" do
      uuid = UUID.uuid4()
      coach = %{user_role: "coach", uuid: uuid}

      token = UserSessions.start(coach)
      {:ok, session} = Redis.get(token)

      assert %{
               "uuid" => ^uuid,
               "role" => "coach",
               "organization_uuid" => nil,
               "token" => ^token,
               "session_id" => _,
               "timestamp" => _
             } = Jason.decode!(session)
    end

    test "stores a new session for a admin" do
      uuid = UUID.uuid4()
      admin = %{user_role: "admin", uuid: uuid}

      token = UserSessions.start(admin)
      {:ok, session} = Redis.get(token)

      assert %{
               "uuid" => ^uuid,
               "role" => "admin",
               "organization_uuid" => nil,
               "token" => ^token,
               "session_id" => _,
               "timestamp" => _
             } = Jason.decode!(session)
    end

    test "updates storage when there are changes" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)
      student = %{user_role: "student", uuid: uuid, organization_id: 1}


      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student"
        })
      )

      UserSessions.start(student, token, %{
        "app_version" => "app-1.1",
        "os_version" => "os-1.1",
        "device_type" => "device-Awesome",
        "ip" => "1.1.1.1",
        "ip_location" => "US",
        "organization_uuid" => "organization_uuid"
      })

      {:ok, session} = Redis.get(token)

      assert %{
               "uuid" => ^uuid,
               "role" => "student",
               "organization_uuid" => "organization_uuid",
               "token" => ^token,
               "session_id" => _,
               "app_version" => "app-1.1",
               "os_version" => "os-1.1",
               "device_type" => "device-Awesome",
               "ip" => "1.1.1.1",
               "ip_location" => "US",
               "timestamp" => _
             } = Jason.decode!(session)

      assert_received [
        :publish,
        "student-profile.update",
        %{
          "attributes" => %{"last_app_session_date" => _},
          "organization_uuid" => "organization_uuid",
          "student_uuid" => ^uuid
        }
      ]

      assert_received [
        :publish,
        "user.update",
        %{
          "last_app_activity" => _,
          "uuid" => ^uuid
        }
      ]
    end

    test "prunes user authlist of expired or removed session tokens" do
      student = %{user_role: "student", uuid: UUID.uuid4()}

      key = UserSessions.auth_list_key(student.uuid)

      Redis.rpush(key, "expired")

      token = UserSessions.start(student)
      Process.sleep(50)
      assert {:ok, [token]} == Redis.get_list(key)
    end
  end

  describe "restore/1" do
    test "restores a session for student" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)
      organization_uuid = UUID.uuid4()
      timestamp = Text.iso8601_now()

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student",
          "organization_uuid" => organization_uuid,
          "token" => token,
          "session_id" => UUID.uuid4(),
          "timestamp" => timestamp
        })
      )

      assert {:ok,
              %{
                "uuid" => ^uuid,
                "role" => "student",
                "organization_uuid" => ^organization_uuid,
                "session_id" => _,
                "app_version" => "app-1.1",
                "os_version" => "os-1.1",
                "device_type" => "device-Awesome",
                "ip" => "1.1.1.1",
                "ip_location" => "US",
                "timestamp" => _
              }} =
               UserSessions.restore(token, %{
                 "app_version" => "app-1.1",
                 "os_version" => "os-1.1",
                 "device_type" => "device-Awesome",
                 "ip" => "1.1.1.1",
                 "ip_location" => "US"
               })
    end

    test "restores app version and last mobile app from profile" do
      uuid = UUID.uuid4()
      organization_uuid = UUID.uuid4()

      token = UserSessions.generate_token(uuid)
      timestamp = Text.iso8601_now()

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student",
          "organization_uuid" => organization_uuid,
          "app_version" => "1.0",
          "device_type" => "iOS",
          "token" => token,
          "session_id" => UUID.uuid4(),
          "timestamp" => timestamp
        })
      )

      assert {:ok,
              %{
                "uuid" => ^uuid,
                "role" => "student",
                "organization_uuid" => ^organization_uuid,
                "session_id" => _,
                "app_version" => "1.0",
                "device_type" => "iOS",
                "timestamp" => _
              }} = UserSessions.restore(token, %{app_version: "1.0", device_type: "iOS"})

      refute_received [:publish, "student-profile.update", %{}]
      refute_received [:publish, "user.update", %{}]
    end

    test "restores a session for a coach" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)
      timestamp = Text.iso8601_now()

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "coach",
          "token" => token,
          "session_id" => UUID.uuid4(),
          "timestamp" => timestamp
        })
      )

      assert {:ok,
              %{
                "uuid" => ^uuid,
                "role" => "coach",
                "organization_uuid" => nil,
                "session_id" => _,
                "timestamp" => _
              }} = UserSessions.restore(token)
    end

    test "stores a new session for a admin" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)
      timestamp = Text.iso8601_now()

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "admin",
          "organization_uuid" => nil,
          "token" => token,
          "session_id" => UUID.uuid4(),
          "timestamp" => timestamp
        })
      )

      assert {:ok,
              %{
                "uuid" => ^uuid,
                "role" => "admin",
                "organization_uuid" => nil,
                "session_id" => _,
                "timestamp" => _
              }} = UserSessions.restore(token)
    end

    test "saves changes to session_id" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)
      organization_uuid = UUID.uuid4()
      timestamp = Text.iso8601_now()

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student",
          "organization_uuid" => organization_uuid,
          "token" => token,
          "session_id" => nil,
          "timestamp" => timestamp
        })
      )

      {:ok,
       %{
         "session_id" => session_id
       }} = UserSessions.restore(token)

      assert Text.is_uuid?(session_id)
    end

    test "does not publish profile update when no qualifying change" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)
      organization_uuid = UUID.uuid4()
      timestamp = Text.iso8601_now()

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student",
          "organization_uuid" => organization_uuid,
          "token" => token,
          "session_id" => nil,
          "timestamp" => timestamp
        })
      )

      assert {:ok,
              %{
                "uuid" => ^uuid,
                "role" => "student",
                "organization_uuid" => ^organization_uuid,
                "session_id" => _,
                "timestamp" => _
              }} = UserSessions.restore(token)

      refute_received [:publish, "student-profile.update", %{}]
    end

    test "publishes profile update for last_app_session_date change" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)
      organization_uuid = UUID.uuid4()
      timestamp = Text.iso8601_now(minutes: -60)

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student",
          "organization_uuid" => organization_uuid,
          "token" => token,
          "session_id" => nil,
          "timestamp" => timestamp
        })
      )

      UserSessions.restore(token)

      assert_received [
        :publish,
        "student-profile.update",
        %{
          "attributes" => %{"last_app_session_date" => _},
          "organization_uuid" => ^organization_uuid,
          "student_uuid" => ^uuid
        }
      ]
    end

    test "publishes profile update for device_type and app_version change" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)
      organization_uuid = UUID.uuid4()
      timestamp = Text.iso8601_now(minutes: -60)

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student",
          "organization_uuid" => organization_uuid,
          "token" => token,
          "session_id" => nil,
          "device_type" => "iOS",
          "app_version" => "1.0",
          "timestamp" => timestamp
        })
      )

      UserSessions.restore(token, %{"app_version" => "2.0", "device_type" => "Android"})

      assert_received [
        :publish,
        "student-profile.update",
        %{
          "attributes" => %{"last_mobile_app" => _, "mobile_app_version" => _},
          "organization_uuid" => ^organization_uuid,
          "student_uuid" => ^uuid
        }
      ]

      assert_received [
        :publish,
        "user.update",
        %{
          "last_app_activity" => _,
          "uuid" => ^uuid
        }
      ]
    end

    test "with invalid token" do
      assert {:error, :not_found, _} = UserSessions.restore(UUID.uuid4())
    end
  end

  describe "terminate/1" do
    test "saves changes to session_id" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student",
          "organization_uuid" => UUID.uuid4(),
          "token" => token,
          "session_id" => UUID.uuid4(),
          "timestamp" => Text.iso8601_now()
        })
      )

      {:ok, _} = UserSessions.terminate(token)

      assert {:ok, nil} = Redis.get(token)
    end

    test "prunes user authlist of expired or removed session tokens" do
      uuid = UUID.uuid4()
      student = %{user_role: "student", uuid: uuid}

      token = UserSessions.start(student)
      key = UserSessions.auth_list_key(student.uuid)
      Process.sleep(50)
      Redis.rpush(key, "expired")

      {:ok, _} = UserSessions.terminate(token)
      Process.sleep(50)

      assert {:ok, []} = Redis.get_list(key)
    end

    test "with invalid token" do
      assert {:error, :not_found, _} = UserSessions.terminate(UUID.uuid4())
    end
  end

  describe "get/1" do
    test "retrieves a unmodified session" do
      uuid = UUID.uuid4()
      token = UserSessions.generate_token(uuid)

      Redis.set(
        token,
        Jason.encode!(%{
          "uuid" => uuid,
          "role" => "student",
          "organization_uuid" => "xyz",
          "token" => token,
          "session_id" => "session",
          "ip" => "1.1.1.1",
          "ip_location" => "US",
          "timestamp" => "2019-01-02"
        })
      )

      assert {:ok,
              %{
                "uuid" => uuid,
                "role" => "student",
                "organization_uuid" => "xyz",
                "session_id" => "session",
                "app_version" => nil,
                "os_version" => nil,
                "device_type" => nil,
                "timestamp" => "2019-01-02",
                "ip" => "1.1.1.1",
                "ip_location" => "US"
              }} == UserSessions.get(token)
    end

    test "invalid token" do
      assert {:error, :not_found, _} = UserSessions.get(UUID.uuid4())
    end
  end

  def clear_sessions do
    ""
    |> UserSessions.auth_list_key()
    |> Redis.keys()
    |> case do
      {:ok, list} -> list
      _ -> []
    end
    |> Enum.each(fn key ->
      key
      |> Redis.get_list()
      |> case do
        {:ok, list} -> list
        _ -> []
      end
      |> Redis.delete()

      Redis.delete(key)
    end)
  end
end
