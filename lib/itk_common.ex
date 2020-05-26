defmodule ITKCommon do
  @moduledoc """
  Provides common logic for elixir projects.
  """
  use Application

  alias ITKCommon.ScheduledTasks.Publisher

  defdelegate schedule_task(routing_key, payload, publish_at), to: Publisher, as: :publish_create

  defdelegate schedule_task(routing_key, payload, publish_at, options),
    to: Publisher,
    as: :publish_create

  defdelegate unschedule_task(routing_key, identifier),
    to: Publisher,
    as: :publish_delete

  @doc false
  def start(_type, _args) do
    opts = [strategy: :rest_for_one, name: ITKCommon.Supervisor]

    environment()
    |> children
    |> Supervisor.start_link(opts)
  end

  def testing? do
    environment() == :test && !running_library_tests?()
  end

  @doc false
  def running_library_tests? do
    Application.get_env(:itk_common, :running_library_tests, false)
  end

  defp environment do
    Application.get_env(:itk_common, :env)
  end

  defp children(:test) do
    if running_library_tests?() do
      children()
    else
      []
    end
  end

  defp children(_), do: children()

  defp children do
    []
    |> append(:redis, ITKCommon.Redis.Pool)
    |> Enum.reverse()
  end

  defp append(list, key, mod) do
    case Application.get_env(:itk_common, key) do
      nil -> list
      _ -> [mod | list]
    end
  end
end
