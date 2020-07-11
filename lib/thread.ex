defmodule ITKCommon.Thread do
  @moduledoc """
  Per-process registry.
  """

  @key :itk_common_thread

  @spec get(key :: String.t()) :: any
  def get(key) when is_binary(key) do
    Map.get(to_map(), key)
  end

  @spec put(key :: String.t(), val :: any) :: map
  def put(key, val) when is_binary(key) do
    new_map = Map.put(to_map(), key, val)
    Process.put(@key, new_map)
    new_map
  end

  @spec put_new(key :: String.t(), val :: any) :: map
  def put_new(key, val) do
    new_map = Map.put_new(to_map(), key, val)
    Process.put(@key, new_map)
    new_map
  end

  def to_map do
    Process.get(@key, %{})
  end
end