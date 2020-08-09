defmodule ITKCommon.FeaturesTest do
  use ExUnit.Case, async: true

  alias ITKCommon.Features
  alias ITKCommon.Utils.Text

  setup do
    on_exit(fn ->
      Features.redis_clear()
    end)
  end

  describe "on?/1" do
    test "returns false when not set" do
      key = UUID.uuid4()

      refute Features.on?(key)
    end

    test "returns true when set" do
      key = UUID.uuid4()
      Features.redis_set(key, Text.iso8601_now())

      assert Features.on?(key)
    end
  end

  describe "on!/1" do
    test "sets to timestamp" do
      key = UUID.uuid4()
      Features.on!(key)
      assert Regex.match?(~r/^\d{4}-\d{2}-\d{2}/, Features.redis_get(key))
    end
  end

  describe "off?/1" do
    test "returns false when set" do
      key = UUID.uuid4()

      assert Features.off?(key)
    end

    test "returns true when not set" do
      key = UUID.uuid4()
      Features.redis_set(key, Text.iso8601_now())

      refute Features.off?(key)
    end
  end

  describe "off!/1" do
    test "deletes flag at key" do
    end
  end

  describe "set/2" do
    test "sets an arbitrary value at key" do
      key = UUID.uuid4()
      Features.redis_set(key, Text.iso8601_now())

      assert Features.on?(key)
      Features.off!(key)
      refute Features.on?(key)
    end
  end

  describe "all/0" do
    test "gets all features" do
      key = UUID.uuid4()
      Features.redis_set(key, "value1")
      key2 = UUID.uuid4()
      Features.redis_set(key2, "value2")

      assert %{
               key => "value1",
               key2 => "value2"
             } == Features.all()
    end
  end

  describe "eq?/2" do
    test "true when value at key equals other" do
      key = UUID.uuid4()
      Features.redis_set(key, "value1")

      assert Features.eq?(key, "value1")
    end

    test "false when value at key does not equals other" do
      key = UUID.uuid4()
      Features.redis_set(key, "value2")

      refute Features.eq?(key, "value1")
    end
  end

  describe "gt?/2" do
    test "true when value at key greater than other" do
      key = UUID.uuid4()
      Features.redis_set(key, "01")

      assert Features.gt?(key, "00")
    end

    test "false when value at key not greater than other" do
      key = UUID.uuid4()
      Features.redis_set(key, "00")

      refute Features.gt?(key, "00")
      refute Features.gt?(key, "01")
    end
  end

  describe "gte?/2" do
    test "true when value at key greater than or equal to other" do
      key = UUID.uuid4()
      Features.redis_set(key, "01")

      assert Features.gte?(key, "00")
      assert Features.gte?(key, "01")
    end

    test "false when value at key less than to other" do
      key = UUID.uuid4()
      Features.redis_set(key, "00")

      refute Features.gte?(key, "01")
    end
  end

  describe "lt?/2" do
    test "true when value at key less than or equal to other" do
      key = UUID.uuid4()
      Features.redis_set(key, "00")

      assert Features.lt?(key, "01")
    end

    test "false when value at key greater than or equal to other" do
      key = UUID.uuid4()
      Features.redis_set(key, "01")

      refute Features.lt?(key, "01")
      refute Features.lt?(key, "00")
    end
  end

  describe "lte?/2" do
    test "true when value at key less than or equal to other" do
      key = UUID.uuid4()
      Features.redis_set(key, "00")

      assert Features.lte?(key, "01")
      assert Features.lte?(key, "00")
    end

    test "false when value at key greater than to other" do
      key = UUID.uuid4()
      Features.redis_set(key, "01")

      refute Features.lte?(key, "00")
    end
  end
end
