defmodule ITKCommon.EtsCache do
  @moduledoc """
  Module to map an a arbitrary key to value and store in ets table
  """

  defmacro __using__([]) do
    quote generated: true do
      def ets_set(key, func) when is_function(func, 0) do
        ITKCommon.EtsCache.set(__MODULE__, key, func.())
      end

      def ets_set(key, value) do
        ITKCommon.EtsCache.set(__MODULE__, key, value)
      end

      def ets_get(key, func) when is_function(func, 0) do
        ITKCommon.EtsCache.get(__MODULE__, key, func)
      end

      def ets_get(key) do
        ITKCommon.EtsCache.get(__MODULE__, key)
      end
    end
  end

  def set(name, key, func) when is_atom(name) and is_function(func, 0) do
    set(name, key, func.())
  end

  def set(name, key, value) when is_atom(name) do
    name
    |> check_for_ets_table()
    |> do_set(key, value)
  end

  def get(name, key, func) when is_atom(name) and is_function(func, 0) do
    name
    |> check_for_ets_table()
    |> from_cache(name, key)
    |> from_source(key, func)
  end

  def get(name, key) when is_atom(name) do
    name
    |> check_for_ets_table()
    |> from_cache(name, key)
    |> case do
      {:ok, value} -> value
      _ -> nil
    end
  end

  defp check_for_ets_table(name) do
    case :ets.whereis(name) do
      :undefined -> build_table(name)
      ref -> ref
    end
  end

  defp from_cache(ref, _name, key) do
    case :ets.lookup(ref, key) do
      [] -> {:miss, ref}
      [{_key, value} | _] -> {:ok, value}
    end
  end

  defp from_source({:ok, value}, _key, _func) do
    value
  end

  defp from_source({:miss, ref}, key, func) do
    do_set(ref, key, func.())
  end

  defp do_set(ref, key, value) do
    :ets.insert(ref, {key, value})
    value
  end

  defp build_table(name) do
    :ets.new(name, [:set, :named_table, :public])
  end
end
