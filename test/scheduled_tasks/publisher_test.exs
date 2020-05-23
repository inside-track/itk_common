defmodule ITKCommon.ScheduledTasks.PublisherTest do
  use ExUnit.Case

  alias ITKCommon.ScheduledTasks.Publisher

  describe "publish/3" do
    test "publishes to the scheduled tasks queue" do
      time = Timex.shift(DateTime.utc_now(), days: 1)

      Publisher.publish(
        "unknown.key",
        %{"arbitrary" => "value"},
        time
      )

      assert_received [
        :publish,
        "scheduled_task.create",
        %{
          "routing_key" => "unknown.key",
          "payload" => %{"arbitrary" => "value"},
          "publish_at" => ^time
        }
      ]
    end
  end

  describe "publish/4" do
    test "publishes to the scheduled tasks queue" do
      time = Timex.shift(DateTime.utc_now(), days: 1)

      Publisher.publish(
        "unknown.key",
        %{"arbitrary" => "value"},
        time,
        [
          identifier: "abc",
          headers: %{"aheader" => "avalue"}
        ]
      )

      assert_received [
        :publish,
        "scheduled_task.create",
        %{
          "routing_key" => "unknown.key",
          "payload" => %{"arbitrary" => "value"},
          "publish_at" => ^time,
          "identifier" => "abc",
          "headers" => %{"aheader" => "avalue"}
        }
      ]
    end
  end
end
