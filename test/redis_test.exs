defmodule ITKCommon.RedisTest do
  use ExUnit.Case

  alias ITKCommon.Redis

  describe "get/1" do
    test "Get value from redis" do
      key = random_key()
      Redis.set(key, "val")
      assert Redis.get(key) == {:ok, "val"}
      del(key)
    end

    test "Get value for non existing key" do
      key = random_key()
      assert Redis.get(key) == {:ok, nil}
    end
  end

  describe "mget/1" do
    test "Get multiple values from redis" do
      keys = [key1, key2] = [random_key(), random_key()]

      Redis.set(key1, "val1")
      Redis.set(key2, "val2")

      assert Redis.mget(keys) == {:ok, ["val1", "val2"]}
      del(keys)
    end

    test "Get values for non existing keys" do
      keys = [random_key(), random_key()]

      assert Redis.mget(keys) == {:ok, [nil, nil]}
    end
  end

  describe "hget/2" do
    test "Get field value from redis" do
      key = random_key()
      Redis.hset(key, "f1", "val")
      assert Redis.hget(key, "f1") == {:ok, "val"}
      del(key)
    end

    test "Get value for non existing key" do
      key = random_key()
      Redis.hset(key, "f2", "val")
      assert Redis.hget(key, "f1") == {:ok, nil}
      del(key)
    end
  end

  describe "hsetnx/3" do
    test "New set cant override a previous set" do
      key = random_key()
      Redis.hset(key, "f1", "val1")
      Redis.hsetnx(key, "f1", "val2")
      assert Redis.hget(key, "f1") == {:ok, "val1"}
      del(key)
    end
  end

  describe "exists?/1" do
    test "true when exists" do
      key = random_key()
      Redis.set(key, "val")
      assert Redis.exists?(key) == true
      del(key)
    end

    test "false when not exists" do
      key = random_key()
      assert Redis.exists?(key) == false
      del(key)
    end
  end

  defp random_key do
    1_000_000_000_000
    |> :rand.uniform()
    |> to_string()
  end

  defp del(keys) when is_list(keys) do
    Enum.each(keys, &del/1)
  end

  defp del(key) do
    Redis.delete(key)
  end
end
