defmodule ITKCommon.CIPToSOCTest do
  use ExUnit.Case

  alias ITKCommon.CIPToSOC

  describe "get/1" do
    test "looking up socs by string" do
      assert CIPToSOC.get("52.0101") == ["11-1021", "11-1011"]

      assert CIPToSOC.get("31.0399") == ["11-1021"]
    end

    test "looking up socs by list" do
      assert CIPToSOC.get(["44.0401", "31.0399"]) == ["11-1021", "11-1011"]
    end
  end

  describe "get_careers/1" do
    test "looking up careers by string" do
      assert CIPToSOC.get_careers("52.0101") == [
               {"11-1021", "General and Operations Managers"},
               {"11-1011", "Chief Executives"}
             ]

      assert CIPToSOC.get_careers("31.0399") == [{"11-1021", "General and Operations Managers"}]
    end

    test "looking up careers by list" do
      assert CIPToSOC.get_careers(["44.0401", "31.0399"]) == [
               {"11-1021", "General and Operations Managers"},
               {"11-1011", "Chief Executives"}
             ]
    end
  end
end
