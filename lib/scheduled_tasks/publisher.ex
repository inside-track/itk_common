defmodule ITKCommon.ScheduledTasks.Publisher do
  @moduledoc """
  Publishes to the delay queue.
  """

  def publish_create(routing_key, payload = %{}, publish_at, options \\ []) do
    data =
      %{
        "routing_key" => routing_key,
        "payload" => payload,
        "publish_at" => publish_at
      }
      |> add_identifier(options)
      |> add_headers(options)

    ITKQueue.publish("scheduled_task.create", data)
  end

  def publish_delete(routing_key, identifier) do
    ITKQueue.publish("scheduled_task.delete", %{
      "routing_key" => routing_key,
      "identifier" => identifier
    })
  end

  defp add_headers(data, opts) do
    case Keyword.get(opts, :headers) do
      nil -> data
      headers -> Map.put(data, "headers", headers)
    end
  end

  defp add_identifier(data, opts) do
    case Keyword.get(opts, :identifier) do
      nil -> data
      identifier -> Map.put(data, "identifier", identifier)
    end
  end
end
