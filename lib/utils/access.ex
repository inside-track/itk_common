defmodule ITKCommon.Utils.Access do
  @moduledoc """
  Functions to help with digging into nested data structures.
  """

  @doc """
  Performs a `deep_get/3` against the app's configuration.
  """
  @spec config_deep_get(app :: atom, keys :: list, default :: any) :: any
  def config_deep_get(app, keys, default \\ nil) do
    app
    |> Application.get_all_env()
    |> deep_get(keys, default)
  end

  @doc """
  Performs a `deep_fetch!/2` against the app's configuration.
  """
  @spec config_deep_fetch!(app :: atom, keys :: list) :: any
  def config_deep_fetch!(app, keys) do
    app
    |> Application.get_all_env()
    |> deep_fetch!(keys)
  end

  @doc """
  Similar to Kernel.get_in/2, but can safely navigate through lists. Returns
  the value if found, or returns the default value if not found.
  """
  @spec deep_get(data :: map | list, keys :: list, default :: any) :: any
  def deep_get(data, keys, default \\ nil) do
    case walk_keys(data, keys) do
      {:ok, result} -> result
      _not_found -> default
    end
  end

  @doc """
  Similar to Kernel.get_in/2, but can safely navigate through lists. Returns
  a tuple with `{:ok, value}` if deepest value was found, or returns `:error`
  if not found.
  """
  @spec deep_fetch(data :: map | list, keys :: list) :: {:ok, any} | :error
  def deep_fetch(data, keys) do
    case walk_keys(data, keys) do
      {:ok, result} -> {:ok, result}
      _not_found -> :error
    end
  end

  @doc """
  Similar to Kernel.get_in/2, but can safely navigate through lists. Returns
  the value if found, or raises a `KeyError` if not found.
  """
  @spec deep_fetch!(data :: map | list, keys :: list) :: any
  def deep_fetch!(data, keys) do
    case walk_keys(data, keys) do
      {:ok, result} -> result
      {:error, data, key} -> raise KeyError, key: key, term: data
    end
  end

  defp walk_keys(data, keys) do
    Enum.reduce_while(keys, {:ok, data}, fn key, {:ok, val} ->
      fetcher = if is_integer(key), do: Enum, else: Access

      case fetcher.fetch(val, key) do
        {:ok, new_val} -> {:cont, {:ok, new_val}}
        :error -> {:halt, {:error, val, key}}
      end
    end)
  end
end
