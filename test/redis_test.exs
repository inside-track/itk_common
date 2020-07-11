defmodule ITKCommon.RedisTest do
  use ExUnit.Case

  alias ITKCommon.Redis
  #alias ITKCommon.Redis.Core, as: Redis

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

  describe "mget_as_map/1" do
    test "Get multiple values from redis" do
      keys = [key1, key2] = [random_key(), random_key()]

      Redis.set(key1, "val1")
      Redis.set(key2, "val2")

      assert Redis.mget_as_map(keys) == {:ok, %{key1 => "val1", key2 => "val2"}}
      del(keys)
    end

    test "Get values for non existing keys" do
      keys = [key1, key2] = [random_key(), random_key()]

      assert Redis.mget_as_map(keys) == {:ok, %{key1 => nil, key2 => nil}}

      del(keys)
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

  describe "hmset/2" do
    test "set multiple keys" do
      key = random_key()
      fields = [field1, field2] = [random_key(), random_key()]

      map = %{
        field1 => "val1",
        field2 => "val2"
      }

      Redis.hmset(key, map)
      assert {:ok, ^map} = Redis.hmget_as_map(key, fields)

      del(key)
    end
  end
  
  describe "hmget/2" do
    test "Get multiple values from redis" do
      key = random_key()
      fields = [field1, field2] = [random_key(), random_key()]

      Redis.hset(key, field1, "val1")
      Redis.hset(key, field2, "val2")

      assert Redis.hmget(key, fields) == {:ok, ["val1", "val2"]}
      del(key)
    end

    test "Get values for non existing fields" do
      key = random_key()
      fields = [random_key(), random_key()]

      assert Redis.hmget(key,fields) == {:ok, [nil, nil]}

      del(key)
    end
  end

  describe "hmget_as_map/2" do
    test "Get multiple values from redis" do
      key = random_key()
      fields = [field1, field2] = [random_key(), random_key()]

      Redis.hset(key, field1, "val1")
      Redis.hset(key, field2, "val2")

      assert Redis.hmget_as_map(key, fields) == {:ok, %{field1 => "val1", field2 => "val2"}}
      del(key)
    end

    test "Get values for non existing fields" do
      key = random_key()
      fields = [field1, field2] = [random_key(), random_key()]

      assert Redis.hmget_as_map(key, fields) == {:ok, %{field1 => nil, field2 => nil}}

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

  describe "mset/1" do
    test "set multiple keys" do
      keys = [key1, key2] = [random_key(), random_key()]

      map = %{
        key1 => "val1",
        key2 => "val2"
      }

      Redis.mset(map)
      assert {:ok, ^map} = Redis.mget_as_map(keys)

      del(keys)
    end
  end

  describe "prepend/2" do
    test "add a single item to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.prepend(key, "a")
      assert {:ok, ["a"]} = Redis.get_list(key)
      Redis.prepend(key, "b")
      assert {:ok, ["b", "a"]} = Redis.get_list(key)

      del(key)
    end

    test "add many items to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.prepend(key, ["a", "b"])
      assert {:ok, ["b", "a"]} = Redis.get_list(key)

      del(key)
    end
  end

  describe "append/2" do
    test "add a single item to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.append(key, "a")
      assert {:ok, ["a"]} = Redis.get_list(key)
      Redis.append(key, "b")
      assert {:ok, ["a", "b"]} = Redis.get_list(key)

      del(key)
    end

    test "add many items to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.append(key, ["a", "b"])
      assert {:ok, ["a", "b"]} = Redis.get_list(key)

      del(key)
    end
  end

  describe "lpush/2" do
    test "add a single item to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.lpush(key, "a")
      assert {:ok, ["a"]} = Redis.get_list(key)
      Redis.lpush(key, "b")
      assert {:ok, ["b", "a"]} = Redis.get_list(key)

      del(key)
    end

    test "add many items to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.lpush(key, ["a", "b"])
      assert {:ok, ["b", "a"]} = Redis.get_list(key)

      del(key)
    end
  end

  describe "lpushx/2" do
    test "add a single item to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.lpush(key, "a")
      assert {:ok, ["a"]} = Redis.get_list(key)
      Redis.lpushx(key, "b")
      assert {:ok, ["b", "a"]} = Redis.get_list(key)

      del(key)
    end

    test "add many items to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.lpush(key, "a")
      Redis.lpushx(key, ["b", "c"])
      assert {:ok, ["c", "b", "a"]} = Redis.get_list(key)

      del(key)
    end

    test "noop when key does not exist" do
      key = random_key()

      Redis.lpushx(key, "a")
      assert {:ok, []} = Redis.get_list(key)

      del(key)
    end
  end

  describe "rpush/2" do
    test "add a single item to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.rpush(key, "a")
      assert {:ok, ["a"]} = Redis.get_list(key)
      Redis.rpush(key, "b")
      assert {:ok, ["a", "b"]} = Redis.get_list(key)

      del(key)
    end

    test "add many items to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.rpush(key, ["a", "b"])
      assert {:ok, ["a", "b"]} = Redis.get_list(key)

      del(key)
    end
  end

  describe "rpushx/2" do
    test "add a single item to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)
      Redis.rpush(key, "a")
      Redis.rpushx(key, "b")
      assert {:ok, ["a", "b"]} = Redis.get_list(key)

      del(key)
    end

    test "add many items to a list" do
      key = random_key()

      assert {:ok, []} = Redis.get_list(key)

      Redis.rpush(key, ["a"])
      Redis.rpushx(key, ["b", "c"])
      assert {:ok, ["a", "b", "c"]} = Redis.get_list(key)

      del(key)
    end

    test "noop when key does not exist" do
      key = random_key()

      Redis.rpushx(key, "a")
      assert {:ok, []} = Redis.get_list(key)

      del(key)
    end
  end

  describe "multi/1" do
    test "performs many commands" do
      key = random_key()
      key2 = random_key()
      Redis.multi([["SET", key, "a"], ["SET", key2, "b"]])

      assert {:ok, "a"} == Redis.get(key)
      assert {:ok, "b"} == Redis.get(key2)

      del([key, key2])
    end

    test "returns result of last command" do
      key = random_key()
      assert {:ok, "a"} == Redis.multi([["SET", key, "a"], ["GET", key], ["GET", "v"]])

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
