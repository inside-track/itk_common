defmodule ITKCommon.Id_To_Uuid do
  @moduledoc """
  Module to extend capability to map an ids to uuids
  """

  defmacro __using__([]) do
    [mod, func] =
      Application.get_env(:itk_common, __CALLER__.module, [
        ITKCommon.Id_To_Uuid,
        &ITKCommon.Id_To_Uuid.error_func/1
      ])

    quote do
      def get(id) when is_integer(id) do
        ITKCommon.Id_To_Uuid.get(__MODULE__, id, unquote(mod), unquote(func))
      end
    end
  end

  def error_func(_) do
    raise "No source function defined"
  end

  def get(client_mod, id, mod, func) when is_integer(id) do
    ITKCommon.EtsWrapper.get(client_mod, id, fn ->
      mod
      |> apply(func, [id])
      |> case do
        {:ok, %{uuid: uuid}} -> uuid
        _ -> nil
      end
    end)
  end
end
