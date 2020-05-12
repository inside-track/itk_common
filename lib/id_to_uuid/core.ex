defmodule ITKCommon.Id_To_Uuid.Core do
  @moduledoc """
  Module to extend capability to map an ids to uuids
  """

  require ITKCommon.Id_To_Uuid.Util
  alias ITKCommon.Id_To_Uuid.Util

  defmacro __using__([]) do
    [mod, func] =
      Application.get_env(:itk_common, __CALLER__.module, [
        Util,
        &Util.error_func/1
      ])

    quote do
      def get(id) when is_integer(id) do
        Util.get(__MODULE__, id, unquote(mod), unquote(func))
      end
    end
  end
end
