defmodule ITKCommon.IdToUuid do
  @moduledoc """
  Module to extend capability to map an ids to uuids
  """

  defmacro __using__([]) do
    [mod, func] =
      Application.get_env(:itk_common, __CALLER__.module, [
        ITKCommon.IdToUuid,
        &ITKCommon.IdToUuid.error_func/1
      ])

    quote generated: true do
      def get(id) when is_integer(id) do
        ITKCommon.IdToUuid.get(__MODULE__, id, unquote(mod), unquote(func))
      end

      def configured? do
        unquote(mod) != ITKCommon.IdToUuid
      end
    end
  end

  def error_func(_) do
    raise "No source function defined"
  end

  def get(client_mod, id, mod, func) when is_integer(id) do
    ITKCommon.EtsCache.get(client_mod, id, fn ->
      mod
      |> apply(func, [id])
      |> case do
        {:ok, %{uuid: uuid}} -> uuid
        _ -> nil
      end
    end)
  end
end
