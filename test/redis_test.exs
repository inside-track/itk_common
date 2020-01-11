defmodule ITKCommon.RedisTest do
  use ExUnit.Case

  alias ITKCommon.Redis

  describe "get/1" do
    test "Get value from redis" do
      Redis.set("key1", "val")
      assert Redis.get("key1") == {:ok, "val"}
      Redis.delete("key1")
      assert Redis.get("key1") == {:ok, nil}
    end

    test "Get value for not excet key" do
      assert Redis.get("key2") == {:ok, nil}
    end
  end

  describe "hget/2" do
    test "Get field value from redis" do
      Redis.hset("key3", "f1", "val")
      assert Redis.hget("key3", "f1") == {:ok, "val"}
      Redis.delete("key3")
      assert Redis.hget("key3", "f1") == {:ok, nil}
    end
  end

  describe "hsetnx/3" do
    test "Get field value after update it" do
      Redis.hsetnx("key4", "f1", "val1")
      Redis.hsetnx("key4", "f1", "val2")
      assert Redis.hget("key4", "f1") == {:ok, "val1"}
      Redis.delete("key4")
      assert Redis.hget("key4", "f1") == {:ok, nil}
    end
  end

  describe "flushall/0" do
    test "delete all keys" do
      Redis.set("key_del", "val")
      assert Redis.get("key_del") == {:ok, "val"}
      Redis.flushall()
      assert Redis.get("key_del") == {:ok, nil}
    end
  end
end
