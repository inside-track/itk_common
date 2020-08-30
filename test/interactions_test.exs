defmodule ITKCommon.InterationsTest do
  use ExUnit.Case

  alias ITKCommon.Interactions
  alias ITKCommon.UserSessions

  describe "capture/2" do
    test "publishes an event from token" do
      user = %{uuid: "xyz", user_role: "student"}

      token =
        UserSessions.start(user, %{
          "app_version" => "app-1.1",
          "os_version" => "os-1.1",
          "device_type" => "device-Awesome",
          "ip" => "1.1.1.1",
          "ip_location" => "US",
          "organization_uuid" => "abc"
        })

      event_data = %{
        "name" => "test_event",
        "arbitrary_data_field" => "hello"
      }

      assert :ok = Interactions.capture("event", event_data, token)

      assert_received [
        :publish,
        "interaction.create",
        %{
          "type" => "event",
          "payload" => %{
            "name" => "test_event",
            "user_uuid" => "xyz",
            "user_role" => "student",
            "organization_uuid" => "abc",
            "session_id" => _,
            "arbitrary_data_field" => "hello",
            "app_version" => "app-1.1",
            "os_version" => "os-1.1",
            "device_type" => "device-Awesome",
            "ip" => "1.1.1.1",
            "ip_location" => "US",
            "timestamp" => _
          }
        }
      ]

      UserSessions.terminate_all(user)
    end

    test "publishes an event with session data" do
      session_data = %{
        "uuid" => "xyz",
        "role" => "student",
        "session_id" => "session_id",
        "organization_uuid" => "abc"
      }

      event_data = %{
        "name" => "test_event",
        "arbitrary_data_field" => "hello"
      }

      assert :ok = Interactions.capture("event", event_data, session_data)

      assert_received [
        :publish,
        "interaction.create",
        %{
          "type" => "event",
          "payload" => %{
            "user_uuid" => "xyz",
            "user_role" => "student",
            "organization_uuid" => "abc",
            "session_id" => "session_id",
            "arbitrary_data_field" => "hello",
            "timestamp" => _
          }
        }
      ]
    end

    test "publishes an event with student" do
      user = %{uuid: "xyz", user_role: "student"}
      UserSessions.start(user, %{"organization_uuid" => "abc"})

      event_data = %{
        "name" => "test_event",
        "arbitrary_data_field" => "hello"
      }

      assert :ok = Interactions.capture("event", event_data, user)

      assert_received [
        :publish,
        "interaction.create",
        %{
          "type" => "event",
          "payload" => %{
            "user_uuid" => "xyz",
            "user_role" => "student",
            "organization_uuid" => "abc",
            "session_id" => _,
            "arbitrary_data_field" => "hello",
            "timestamp" => _
          }
        }
      ]

      UserSessions.terminate_all(user)
    end
  end
end
