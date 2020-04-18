defmodule ITKCommon.Utils.MapTest do
  use ExUnit.Case
  alias ITKCommon.Utils.Map

  describe "atomize_keys/1" do
    test "atomizes keys" do
      map = %{
        "key1" => "value1",
        "key2" => 2,
        "key3" => ["1"],
        "key4" => true
      }

      assert %{
               key1: "value1",
               key2: 2,
               key3: ["1"],
               key4: true
             } = Map.atomize_keys(map)
    end

    test "ignores non string keys" do
      map = %{
        1 => "value1",
        :key2 => 2,
        "key3" => ["1"],
        "key4" => true
      }

      assert %{
               1 => "value1",
               :key2 => 2,
               :key3 => ["1"],
               :key4 => true
             } = Map.atomize_keys(map)
    end

    test "does not atomize nested maps" do
      map = %{
        "key1" => %{"nested_key" => "nested_value"}
      }

      assert %{
               key1: %{"nested_key" => "nested_value"}
             } = Map.atomize_keys(map)
    end
  end

  describe "deep_atomize_keys/1" do
    test "atomizes keys of nested maps" do
      map = %{
        "key1" => %{"nested_key" => %{"nested_key2" => "nested_value"}}
      }

      assert %{
               key1: %{nested_key: %{nested_key2: "nested_value"}}
             } = Map.deep_atomize_keys(map)
    end
  end
end