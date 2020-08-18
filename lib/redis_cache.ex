defmodule ITKCommon.RedisCache do
  @moduledoc """
  Module to map an a arbitrary key to value and store in ets table
  """

  alias ITKCommon.Redis
  alias ITKCommon.Utils.Text

  defmacro __using__(opts) do
    name = Keyword.get(opts, :name)

    quote generated: true do
      Module.put_attribute(
        __MODULE__,
        :redis_cache_key,
        unquote(name) || ITKCommon.RedisCache.cache_name(__MODULE__)
      )

      def redis_set(key, func) when is_function(func, 0) do
        ITKCommon.RedisCache.set(@redis_cache_key, key, func.())
      end

      def redis_set(key, value) do
        ITKCommon.RedisCache.set(@redis_cache_key, key, value)
      end

      def redis_set(map) when is_map(map) do
        ITKCommon.RedisCache.set(@redis_cache_key, map)
      end

      def redis_get(key, func) when is_function(func, 0) do
        ITKCommon.RedisCache.get(@redis_cache_key, key, func)
      end

      def redis_get(key) do
        ITKCommon.RedisCache.get(@redis_cache_key, key)
      end

      def redis_get_all do
        ITKCommon.RedisCache.get_all(@redis_cache_key)
      end

      def redis_del(key) do
        ITKCommon.RedisCache.del(@redis_cache_key, key)
      end

      def redis_clear do
        ITKCommon.RedisCache.clear(@redis_cache_key)
      end

      def cache_name do
        @redis_cache_key
      end
    end
  end

  def set(mod_or_name, map) when is_map(map) do
    do_set(mod_or_name, map)
  end

  def set(mod_or_name, key, func) when is_function(func, 0) do
    do_set(mod_or_name, key, func.())
  end

  def set(mod_or_name, key, value) do
    do_set(mod_or_name, key, value)
  end

  def get(mod_or_name, key, func \\ nil) do
    mod_or_name
    |> cache_name()
    |> Redis.hget(key)
    |> from_source(mod_or_name, key, func)
  end

  def get_all(mod_or_name) do
    mod_or_name
    |> cache_name()
    |> Redis.hget_all()
    |> case do
      {:ok, map} -> map
      error -> error
    end
  end

  def del(mod_or_name, key) do
    name = cache_name(mod_or_name)
    Redis.noreply_command(["HDEL", name, key])
  end

  def clear(mod_or_name) do
    name = cache_name(mod_or_name)
    Redis.noreply_command(["DEL", name])
  end

  defp from_source({:ok, nil}, mod_or_name, key, func) when is_function(func, 0) do
    value =
      case func.() do
        {:ok, src} -> src
        src -> src
      end

    if is_binary(value) do
      do_set(mod_or_name, %{key => value})
    end

    value
  end

  defp from_source({:ok, value}, _mod_or_name, _key, _func) do
    value
  end

  defp do_set(mod_or_name, map) do
    name = cache_name(mod_or_name)
    Redis.hset(name, map)
    map
  end

  defp do_set(mod_or_name, key, value) do
    do_set(mod_or_name, %{key => value})
    value
  end

  def cache_name(name) when is_binary(name) do
    name
  end

  def cache_name(mod) when is_atom(mod) do
    "redis-cache-" <> Text.hypen(mod)
  end
end
