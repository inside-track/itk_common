defmodule ITKCommon.Utils.Map do
  @moduledoc """
  Utilities for interacting with map.
  """

  @doc """
  Stringify map keys.
  """
  @spec stringify_keys(map :: map) :: map
  def stringify_keys(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc -> Map.put(acc, to_string(k), v) end)
  end
end