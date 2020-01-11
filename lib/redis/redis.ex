defmodule ITKCommon.Redis do
  @moduledoc """
  Module for interacting with Redis.
  """

  @type response :: {:ok, Redix.Protocol.redis_value()} | {:error, atom | Redix.Error.t()}

  @doc """
  Gets a value from Redis with the given key.
  """
  # @spec get(key :: String.t()) :: response
  def get(key) when is_binary(key) do
    command(["GET", key])
  end

  @doc """
  Gets multiple value provided by keys or matching pattern
  This should be used sparingly
  """
  def mget(keys) when is_list(keys) do
    command(["MGET" | keys])
  end

  def mget(pattern) when is_binary(pattern) do
    case keys(pattern) do
      {:ok, []} -> []
      {:ok, keys} -> mget(keys)
    end
  end

  @doc """
  Gets multiple keys provided by matching pattern
  This should be used sparingly
  """
  def keys(pattern) when is_binary(pattern) do
    {:ok, scan(pattern)}
  end

  @doc """
  Gets the value associated with field in the hash stored at key.
  """
  # @spec hget(key :: String.t(), field :: String.t()) :: response
  def hget(key, field) when is_binary(key) and is_binary(field) do
    command(["HGET", key, field])
  end

  def hdel(key, field) when is_binary(key) and is_binary(field) do
    command(["HDEL", key, field])
  end

  @doc """
  Gets a list from Redis with the given key.
  """
  # @spec get_list(key :: String.t()) :: response
  def get_list(key) when is_binary(key) do
    command(["LRANGE", key, 0, -1])
  end

  @doc """
  Sets a value in Redis with the given key.
  """
  # @spec set(key :: String.t(), value :: String.t()) :: response
  def set(key, value) when is_binary(key) and is_binary(value) do
    command(["SET", key, value])
  end

  @doc """
  Sets field in the hash stored at key to value.
  """
  # @spec hset(key :: String.t(), field :: String.t(), value :: String.t()) :: response
  def hset(key, field, value) when is_binary(key) and is_binary(field) and is_binary(value) do
    command(["HSET", key, field, value])
  end

  @doc """
  Sets field in the hash stored at key to value, only if field does not yet exist.
  """
  # @spec hsetnx(key :: String.t(), field :: String.t(), value :: String.t()) :: response
  def hsetnx(key, field, value) when is_binary(key) and is_binary(field) and is_binary(value) do
    command(["HSETNX", key, field, value])
  end

  @doc """
  Sets a value in Redis with the given key that expires.
  """
  # @spec set(key :: String.t(), value :: String.t(), ttl :: integer) :: response
  def set(key, value, ttl) when is_binary(key) and is_binary(value) and is_integer(ttl) do
    command(["SET", key, value, "EX", ttl])
  end

  @doc """
  Prepends a value on a list in Redis with the given key.
  """
  # @spec prepend(key :: String.t(), value :: String.t()) :: response
  def prepend(key, value) when is_binary(key) and is_binary(value) do
    command(["LPUSH", key, value])
  end

  def first(key) when is_binary(key) do
    lindex(key, 0)
  end

  def last(key) when is_binary(key) do
    lindex(key, -1)
  end

  def lindex(key, index) when is_binary(key) and is_integer(index) do
    command(["LINDEX", key, index])
  end

  @doc """
  Sets a time-to-live on the given key. After the given time has elapsed the key will be deleted.
  """
  # @spec expire(key :: String.t(), ttl :: integer) :: response
  def expire(key, ttl) when is_binary(key) and is_integer(ttl) do
    command(["EXPIRE", key, ttl])
  end

  @doc """
  Deletes a key from Redis.
  """
  # @spec delete(key :: String.t()) :: response
  def delete(key) when is_binary(key) do
    command(["DEL", key])
  end

  @doc """
  Delete all the keys of all the existing databases.
  """
  # @spec flushall() :: response
  def flushall do
    command(["FLUSHALL"])
  end

  @doc """
  Checks if key exists
  """
  # @spec exists() :: response
  def exists(key) do
    case command(["EXISTS", key]) do
      {:ok, 0} -> false
      {:ok, _} -> true
    end
  end

  @doc """
  alias for exists/1
  """
  # @spec exists() :: response
  def exists?(key), do: exists(key)

  @doc """
  Sends a command to Redis.
  """
  # @spec command(command :: String.t()) :: response
  def command(command) when is_list(command) do
    :poolboy.transaction(:redis_pool, &Redix.command(&1, command))
  end

  defp scan(pattern) do
    scan(pattern, [], "0")
  end

  defp scan(pattern, prev_data, prev_cursor) do
    case command(["SCAN", String.to_integer(prev_cursor), "MATCH", pattern]) do
      {:ok, [cursor, data]} when cursor != "0" and is_list(data) ->
        scan(pattern, [data | prev_data], cursor)

      _ ->
        List.flatten(prev_data)
    end
  end
end
