defmodule ITKCommon.SOCToCIPTest do
  use ExUnit.Case

  alias ITKCommon.SOCToCIP

  describe "get/1" do
    test "looking up cips by string" do
      assert SOCToCIP.get("11-1011") == ["52.0101", "44.0401"]

      assert SOCToCIP.get("11-1021") == ["52.0101", "44.0401", "31.0399"]
    end

    test "looking up cips by list" do
      assert SOCToCIP.get(["11-1021", "11-1011"]) == ["52.0101", "44.0401", "31.0399"]
    end
  end
end
