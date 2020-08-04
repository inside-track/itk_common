defmodule ITKCommon.Utils.AccessTest do
  use ExUnit.Case, async: true

  import ITKCommon.Utils.Access

  setup_all do
    Application.put_env(:test, AccessTest, foo: [bar: [baz: "qux"]])
  end

  defp data do
    [foo: [%{}, %{"bar" => [baz: "qux"]}]]
  end

  describe "config_deep_get/3" do
    test "allows nested lookups" do
      assert config_deep_get(:test, [AccessTest, :foo, :bar, :baz], "xyz") == "qux"
    end

    test "returns default if not found" do
      assert config_deep_get(:test, [AccessTest, :foo, :bleep, :baz], "xyz") == "xyz"
    end
  end

  describe "config_deep_fetch!/2" do
    test "allows nested lookups" do
      assert config_deep_fetch!(:test, [AccessTest, :foo, :bar, :baz]) == "qux"
    end

    test "raises KeyError if not found" do
      assert_raise KeyError, fn ->
        config_deep_fetch!(:test, [AccessTest, :foo, :bleep, :baz])
      end
    end
  end

  describe "deep_get/3" do
    test "allows nested lookups through lists" do
      assert deep_get(data(), [:foo, 1, "bar", :baz]) == "qux"
    end

    test "returns default if not found" do
      assert deep_get(data(), [:foo, 2, "bar", :baz], "xyz") == "xyz"
      assert deep_get(data(), [:foo, 2, "bleep", :baz], "xyz") == "xyz"
    end
  end

  describe "deep_fetch/2" do
    test "allows nested lookups through lists" do
      assert {:ok, "qux"} = deep_fetch(data(), [:foo, 1, "bar", :baz])
    end

    test "returns :error if not found" do
      assert :error = deep_fetch(data(), [:foo, 2, "bar", :baz])
      assert :error = deep_fetch(data(), [:foo, 2, "bleep", :baz])
    end
  end

  describe "deep_fetch!/2" do
    test "allows nested lookups through lists" do
      assert deep_fetch!(data(), [:foo, 1, "bar", :baz]) == "qux"
    end

    test "returns :error if not found" do
      assert_raise KeyError, fn ->
        deep_fetch!(data(), [:foo, 2, "bar", :baz])
      end
    end
  end
end
