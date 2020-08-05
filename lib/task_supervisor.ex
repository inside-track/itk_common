defmodule ITKCommon.TaskSupervisor do
  @moduledoc """
  A task supervisor.
  Please add this module to application tree:
  ```
  children = [
    supervisor(Task.Supervisor, [[name: ITK.TaskSupervisor]])
  ]
  ```
  Start an async task that will not report back:
  ITK.TaskSupervisor.do_async(fn -> IO.puts("Side effects") end)
  """

  @spec do_async(fun :: (() -> any())) :: DynamicSupervisor.on_start_child()
  def do_async(fun) when is_function(fun, 0) do
    Task.Supervisor.start_child(__MODULE__, fun)
  end

  @spec do_async(mod :: atom, func_name :: atom, args :: list(any)) ::
          DynamicSupervisor.on_start_child()
  def do_async(mod, func_name, args) when is_atom(mod) and is_atom(func_name) and is_list(args) do
    Task.Supervisor.start_child(__MODULE__, fn ->
      apply(mod, func_name, args)
    end)
  end
end
