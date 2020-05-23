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
      |> add_uuid(options)
      |> add_headers(options)

    ITKQueue.publish("scheduled_task.create", data)
  end

  defp add_headers(data, headers: headers) do
    data
    |> Map.put("headers", headers)
  end

  defp add_headers(data, _), do: data

  defp add_uuid(data, uuid: uuid) do
    data
    |> Map.put("uuid", uuid)
  end

  defp add_uuid(data, _), do: data
end
