defmodule ITKCommon.Thread do
  @moduledoc """
  Per-process registry.
  """

  @key :itk_common_thread

  def get(key) do
    Map.get(to_map(), key)
  end

  def put(key, val) do
    new_map = Map.put(to_map(), key, val)
    Process.put(@key, new_map)
    new_map
  end

  def put_new(key, val) do
    new_map = Map.put_new(to_map(), key, val)
    Process.put(@key, new_map)
    new_map
  end

  def merge(map) do
    new_map = Map.merge(to_map(), map)
    Process.put(@key, new_map)
    new_map
  end

  def merge_new(map) do
    new_map = Map.merge(map, to_map())
    Process.put(@key, new_map)
    new_map
  end

  def to_map do
    Process.get(@key, %{})
  end
end