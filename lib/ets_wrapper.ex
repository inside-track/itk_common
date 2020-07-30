defmodule ITKCommon.EtsWrapper do
  @moduledoc """
  Module to map an a arbitrary key to value and store in ets table
  """

  def set(name, key, func) when is_atom(name) and is_function(func, 0) do
    do_set(name, key, func.())
  end

  def set(name, key, value) when is_atom(name) do
    do_set(name, key, value)
  end

  def get(name, key, func) when is_atom(name) and is_function(func, 0) do
    name
    |> check_for_ets_table()
    |> get_value_from_cache(name, key)
    |> get_value_from_source(key, func)
  end

  def get(name, key) when is_atom(name) do
    name
    |> check_for_ets_table()
    |> get_value_from_cache(name, key)
    |> case do
      {:ok, value} -> value
      _ -> nil
    end
  end

  defp check_for_ets_table(name) do
    :ets.whereis(name)
  end

  defp get_value_from_cache(:undefined, name, _key) do
    ref = :ets.new(name, [:set, :named_table, :public])
    {:miss, ref}
  end

  defp get_value_from_cache(ref, _name, key) do
    case :ets.lookup(ref, key) do
      [] -> {:miss, ref}
      [{_key, value} | _] -> {:ok, value}
    end
  end

  defp get_value_from_source({:ok, value}, _key, _func) do
    value
  end

  defp get_value_from_source({:miss, ref}, key, func) do
    do_set(ref, key, func.())
  end

  defp do_set(name_or_ref, key, value) do
    :ets.insert(name_or_ref, {key, value})
    value
  end
end
