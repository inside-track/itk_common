defmodule ITKCommon.Utils.TitleSlugTest do
  use ExUnit.Case, async: true

  alias ITKCommon.Utils.TitleSlug

  describe "generate/1" do
    test "generating slug for text" do
      assert TitleSlug.generate(" @! ThIs iS    text !@#$%  ") == "this-is-text"
    end

    test "for empty string" do
      assert TitleSlug.generate("") == ""
    end
  end
end
