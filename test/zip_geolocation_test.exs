defmodule ITKCommon.ZipGeolocationTest do
  use ExUnit.Case, async: true

  alias ITKCommon.ZipGeolocation
  alias ITKCommon.Redis

  setup do
    on_exit(fn ->
      ZipGeolocation.clear()
    end)
  end

  describe "get/1" do
    test "Get geopoint" do
      assert Redis.hget(ZipGeolocation.key(), "loaded") == {:ok, nil}
      Process.sleep(50)
      assert ZipGeolocation.get("00601") == {:ok, "18.180555, -66.749961"}

      assert ZipGeolocation.get("006020000") == {:ok, "18.361945, -67.175597"}
    end

    test "sets loaded flag" do
      assert Redis.hget(ZipGeolocation.key(), "loaded") == {:ok, nil}
      ZipGeolocation.load(%{})
      Process.sleep(50)
      assert Redis.hget(ZipGeolocation.key(), "loaded") == {:ok, "true"}
    end

    test "wrong format zipcode" do
      assert ZipGeolocation.get("0064401") == {:error, "Invalid zipcode format."}
    end

    test "wrong zipcode number" do
      assert ZipGeolocation.get("44434") ==
               {:error, "No geopoint match for this zipcode."}
    end
  end
end
