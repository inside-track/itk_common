defmodule ITKCommon.CIPToSOCTest do
  use ExUnit.Case

  alias ITKCommon.CIPToSOC

  describe "get/1" do
    test "looking up cips by string" do
      assert CIPToSOC.get("52.0101") == ["11-1021", "11-1011"]

      assert CIPToSOC.get("31.0399") == ["11-1021"]
    end

    test "looking up cips by list" do
      assert CIPToSOC.get(["44.0401", "31.0399"]) == ["11-1021", "11-1011"]
    end
  end
end
