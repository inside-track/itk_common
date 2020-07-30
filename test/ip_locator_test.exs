defmodule ITKCommon.IpLocatorTest do
  use ExUnit.Case

  alias ITKCommon.IpLocator
  alias ITKCommon.Redis

  describe "locate/1" do
    test "with initialized store, returns an expected range" do
      IpLocator.block_invalid()

      [{"1.0.0.1", "ZZ"}, {"2.1.1.1", "XX"}, {"3.2.1.2", "YY"}]
      |> Enum.each(fn {ip, code} ->
        assert initialized?()
        assert {:ok, code} == IpLocator.locate(ip)
      end)

      IpLocator.clear()
    end

    test "with initialized store, returns an unexpected range" do
      IpLocator.block_invalid()

      ~w[0.0.0.0 2.3.1.1 255.2.1.2]
      |> Enum.each(fn ip ->
        assert initialized?()
        assert {:ok, "INVALID"} == IpLocator.locate(ip)
      end)

      IpLocator.clear()
    end

    test "detects invalid ip" do
      assert {:error, :invalid_ip} == IpLocator.locate("2000.0.0.0")
      assert {:error, :invalid_ip} == IpLocator.locate(nil)
      assert {:error, :invalid_ip} == IpLocator.locate(%{})
      assert {:error, :invalid_ip} == IpLocator.locate("hello")
    end
  end

  defp initialized? do
    {:ok, int} = Redis.command(["ZCARD", IpLocator.key()])
    int > 1
  end
end
