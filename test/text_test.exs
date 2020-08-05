defmodule ITKCommon.Utils.TextTest do
  use ExUnit.Case, async: true

  alias ITKCommon.Utils.Text

  describe "sanitize/1" do
    test "sanitizes text" do
      assert Text.sanitize("\ufffd\ufffdHello \u0000World") == "\ufffd\ufffdHello World"
    end
  end
end
