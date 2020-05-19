defmodule ITKCommon.ScheduledTasks.Publisher do
  @moduledoc """
  Publishes to the delay queue.
  """

  def publish(routing_key, payload = %{}, publish_at, options \\ []) do
    data =
      %{
        "routing_key" => routing_key,
        "payload" => payload,
        "publish_at" => publish_at
      }
      |> add_request_uuid(options)

    ITKQueue.publish("scheduled_task.create", data)
  end

  defp add_request_uuid(data, request_uuid: request_uuid) do
    data
    |> Map.put("request_uuid", request_uuid)
  end

  defp add_request_uuid(data, _), do: data
end
