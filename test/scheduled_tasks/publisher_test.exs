defmodule ITKCommon.ScheduledTasks.PublisherTest do
  use ExUnit.Case

  alias ITKCommon.ScheduledTasks.Publisher

  describe "publish_create/3" do
    test "publishes to the scheduled tasks create queue" do
      time = Timex.shift(DateTime.utc_now(), days: 1)

      Publisher.publish_create(
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

  describe "publish_create/4" do
    test "publishes to the scheduled tasks create queue" do
      time = Timex.shift(DateTime.utc_now(), days: 1)

      Publisher.publish_create(
        "unknown.key",
        %{"arbitrary" => "value"},
        time,
        identifier: "abc",
        headers: %{"aheader" => "avalue"}
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

  describe "publish_delete" do
    test "publishes to the scheduled tasks delete queue" do
      Publisher.publish_delete(
        "unknown.key",
        "abc"
      )

      assert_received [
        :publish,
        "scheduled_task.delete",
        %{
          "routing_key" => "unknown.key",
          "identifier" => "abc"
        }
      ]
    end
  end
end
