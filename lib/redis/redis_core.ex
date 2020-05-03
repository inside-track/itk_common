defmodule ITKCommon.RedisCore do
  @moduledoc """
  Core module to extend capabilities for interacting with Redis.
  """
  defmacro __using__([]) do
    quote do
      @doc """
      Gets a value from Redis with the given key.
      """
      def get(key) when is_binary(key) do
        command(["GET", key])
      end

      def g(key) when is_binary(key) do
        command(["GET", key])
      end


      @doc """
      Gets multiple value provided by keys
      By matching pattern should be used sparingly
      """
      def mget(keys) when is_list(keys) do
        command(["MGET" | keys])
      end

      def mget(pattern) when is_binary(pattern) do
        case keys(pattern) do
          {:ok, []} ->
            {:ok, []}

          {:ok, keys} ->
            mget(keys)

          other ->
            other
        end
      end

      @doc """
      Gets multiple values provided by keys
      Returns a Map of key value pairs
      By matching pattern should be used sparingly
      """
      def mget_as_map(keys) do
        case mget(keys) do
          {:ok, []} ->
            {:ok, %{}}

          {:ok, list} ->
            map =
              keys
              |> Enum.zip(list)
              |> Enum.into(%{})

            {:ok, map}

          other ->
            other
        end
      end

      @doc """
      Set multiple values provided by key => value Map
      """
      def mset(map) when is_map(map) do
        args =
          map
          |> Enum.map(fn {key, value} ->
            [key, value]
          end)
          |> List.flatten()

        command(["MSET" | args])
      end

      @doc """
      Get a value and set in one atomic operation
      """
      def getset(key, value) when is_binary(key) and is_binary(value) do
        command(["GETSET", key, value])
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
      def hget(key, field) when is_binary(key) and is_binary(field) do
        command(["HGET", key, field])
      end

      def hdel(key, field) when is_binary(key) and is_binary(field) do
        command(["HDEL", key, field])
      end

      @doc """
      Gets a list from Redis with the given key.
      """
      def get_list(key) when is_binary(key) do
        command(["LRANGE", key, 0, -1])
      end

      @doc """
      Sets a value in Redis with the given key.
      """
      def set(key, value) when is_binary(key) and is_binary(value) do
        command(["SET", key, value])
      end

      @doc """
      Sets a value in Redis with the given key that expires.
      """
      def set(key, value, ttl) when is_binary(key) and is_binary(value) and is_integer(ttl) do
        command(["SET", key, value, "EX", ttl])
      end

      @doc """
      Sets a value in Redis with the given key if given key does not exist.
      """
      def setnx(key, value) when is_binary(key) and is_binary(value) do
        command(["SETNX", key, value])
      end

      @doc """
      Sets field in the hash stored at key to value.
      """
      def hset(key, field, value) when is_binary(key) and is_binary(field) and is_binary(value) do
        command(["HSET", key, field, value])
      end

      @doc """
      Sets field in the hash stored at key to value, only if field does not yet exist.
      """
      def hsetnx(key, field, value)
          when is_binary(key) and is_binary(field) and is_binary(value) do
        command(["HSETNX", key, field, value])
      end

      @doc """
      Prepends a value on a list in Redis with the given key.
      """
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
      def expire(key, ttl) when is_binary(key) and is_integer(ttl) do
        command(["EXPIRE", key, ttl])
      end

      @doc """
      Deletes a key from Redis.
      """
      def delete(key) when is_binary(key) do
        command(["DEL", key])
      end

      @doc """
      Delete all the keys of all the existing databases.
      """
      def flushall do
        command(["FLUSHALL"])
      end

      @doc """
      Checks if key exists
      """
      def exists(key) do
        case command(["EXISTS", key]) do
          {:ok, 0} -> false
          {:ok, _} -> true
        end
      end

      @doc """
      alias for exists/1
      """
      def exists?(key), do: exists(key)

      @doc """
      Sends a command to Redis.
      """
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
  end
end
