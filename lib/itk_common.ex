defmodule ITKCommon do
  @moduledoc """
  Provides common logic for elixir projects.
  """
  use Application

  alias ITKCommon.ScheduledTasks.Publisher
  alias ITKCommon.TaskSupervisor
  alias ITKCommon.Interactions

  defdelegate schedule_task(routing_key, payload, publish_at), to: Publisher, as: :publish_create

  defdelegate schedule_task(routing_key, payload, publish_at, options),
    to: Publisher,
    as: :publish_create

  defdelegate unschedule_task(routing_key, identifier),
    to: Publisher,
    as: :publish_delete

  defdelegate do_async(fun), to: TaskSupervisor
  defdelegate do_async(mod, func_name, args), to: TaskSupervisor

  defdelegate capture_event(data, user_or_session_or_token), to: Interactions
  defdelegate capture_experiment(data, user_or_session_or_token), to: Interactions

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
    |> append({Task.Supervisor, name: ITKCommon.TaskSupervisor})
    |> Enum.reverse()
  end

  defp append(list, key, mod) do
    case Application.get_env(:itk_common, key) do
      nil -> list
      _ -> append(list, mod)
    end
  end

  defp append(list, mod) do
    [mod | list]
  end
end
