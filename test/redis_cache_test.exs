defmodule ITKCommon.RedisCacheTest do
  use ExUnit.Case, async: true

  alias ITKCommon.Redis

  defmodule Example do
    use ITKCommon.RedisCache
  end

  setup do
    on_exit(fn ->
      Example.redis_clear()
    end)
  end

  describe "redis_get/1" do
    test "returns a value stored in the table" do
      key = UUID.uuid4()
      Redis.hset(Example.cache_name(), key, "test_value")

      assert "test_value" == Example.redis_get(key)
    end

    test "returns nil if key doesnt exist" do
      key = UUID.uuid4()

      assert is_nil(Example.redis_get(key))
    end
  end

  describe "redis_get/2" do
    test "returns a value stored in the table" do
      key = UUID.uuid4()
      Redis.hset(Example.cache_name(), key, "test_value")

      assert "test_value" == Example.redis_get(key, fn -> "value_from_func" end)
    end

    test "stores return value of function if key doesnt exist" do
      key = UUID.uuid4()
      assert "value_from_func" == Example.redis_get(key, fn -> "value_from_func" end)
      assert "value_from_func" == Example.redis_get(key)
    end
  end

  describe "redis_set/2" do
    test "stores a value" do
      key = UUID.uuid4()
      assert "test_value" == Example.redis_set(key, "test_value")
      assert "test_value" == Example.redis_get(key)
    end

    test "stores a value from func" do
      key = UUID.uuid4()
      assert "value_from_func" == Example.redis_set(key, fn -> "value_from_func" end)
      assert "value_from_func" == Example.redis_get(key)
    end
  end

  describe "redis_del/1" do
    test "removes a key" do
      key = UUID.uuid4()
      Example.redis_set(key, "test_value")
      assert "test_value" == Example.redis_get(key)
      Example.redis_del(key)
      assert is_nil(Example.redis_get(key))
    end
  end

  describe "redis_get_all/0" do
    test "get all keys/values" do
      key1 = UUID.uuid4()
      key2 = UUID.uuid4()
      key3 = UUID.uuid4()
      Example.redis_set(key1, "test_value")
      Example.redis_set(key2, "test_value")
      Example.redis_set(key3, "test_value")

      assert %{
               key1 => "test_value",
               key2 => "test_value",
               key3 => "test_value"
             } == Example.redis_get_all()
    end
  end

  describe "redis_clear/0" do
    test "removes all keys" do
      key1 = UUID.uuid4()
      key2 = UUID.uuid4()
      key3 = UUID.uuid4()
      Example.redis_set(key1, "test_value")
      Example.redis_set(key2, "test_value")
      Example.redis_set(key3, "test_value")

      Example.redis_clear()
      assert %{} == Example.redis_get_all()
    end
  end
end
