defmodule ITKCommon.EtsCacheTest do
  use ExUnit.Case

  defmodule Example do
    use ITKCommon.EtsCache
  end

  describe "ets_get/1" do
    test "returns a value stored in the table" do
      key = UUID.uuid4()

      Example
      |> :ets.new([:set, :named_table, :public])
      |> :ets.insert({key, "test_value"})

      assert "test_value" == Example.ets_get(key)
    end

    test "returns nil if key doesnt exist" do
      key = UUID.uuid4()

      assert is_nil(Example.ets_get(key))
    end
  end

  describe "ets_get/2" do
    test "returns a value stored in the table" do
      key = UUID.uuid4()

      Example
      |> :ets.new([:set, :named_table, :public])
      |> :ets.insert({key, "test_value"})

      assert "test_value" == Example.ets_get(key, fn -> "value_from_func" end)
    end

    test "stores return value of function if key doesnt exist" do
      key = UUID.uuid4()
      assert "value_from_func" == Example.ets_get(key, fn -> "value_from_func" end)
      assert "value_from_func" == Example.ets_get(key)
    end
  end

  describe "ets_set/2" do
    test "stores a value" do
      key = UUID.uuid4()
      assert "test_value" == Example.ets_set(key, "test_value")
      assert "test_value" == Example.ets_get(key)
    end

    test "stores a value from func" do
      key = UUID.uuid4()
      assert "value_from_func" == Example.ets_set(key, fn -> "value_from_func" end)
      assert "value_from_func" == Example.ets_get(key)
    end
  end
end
