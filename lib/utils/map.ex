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

  @spec deep_atomize_keys(map :: map) :: map
  def deep_atomize_keys(map) do
    atomize_keys(map, true)
  end

  @spec atomize_keys(map :: map) :: map
  def atomize_keys(map, deep \\ false) when is_map(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      v =
        if deep and is_map(v) do
          deep_atomize_keys(v)
        else
          v
        end

      if is_binary(k) do
        Map.put(acc, String.to_atom(k), v)
      else
        Map.put(acc, k, v)
      end
    end)
  end
end
