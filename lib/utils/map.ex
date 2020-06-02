defmodule ITKCommon.Utils.Map do
  @moduledoc """
  Utilities for interacting with map.
  """

  @doc """
  Stringify map keys.
  """
  @spec deep_stringify_keys(map :: map) :: map
  def deep_stringify_keys(map) do
    stringify_keys(map, true)
  end

  @spec stringify_keys(map :: map) :: map
  def stringify_keys(map, deep \\ false) do
    convert_keys(map, deep, :string)
  end

  @spec deep_atomize_keys(map :: map) :: map
  def deep_atomize_keys(map) do
    atomize_keys(map, true)
  end

  @spec atomize_keys(map :: map) :: map
  def atomize_keys(map, deep \\ false) when is_map(map) do
    convert_keys(map, deep, :atom)
  end

  defp convert_keys(map, deep, conversion) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      v =
        if deep and is_map(v) do
          convert_keys(v, deep, conversion)
        else
          v
        end

      k = convert_key(k, conversion)

      Map.put(acc, k, v)
    end)
  end

  defp convert_key(k, :atom) when is_binary(k), do: String.to_atom(k)
  defp convert_key(k, :string), do: to_string(k)
  defp convert_key(k, _), do: k
end
