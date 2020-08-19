defmodule ITKCommon.OrganizationIdToUuidTest do
  use ExUnit.Case, async: true

  alias ITKCommon.OrganizationIdToUuid

  describe "get/1" do
    test "returns requested uuid" do
      assert "11111111-1111-1111-1111-111111111111" ==
               OrganizationIdToUuid.get(1)
    end

    test "caches the uuid" do
      OrganizationIdToUuid.get(2)

      assert [{2, "22222222-2222-2222-2222-222222222222"} | _] =
               :ets.lookup(OrganizationIdToUuid, 2)
    end

    test "return nil when no match found" do
      assert is_nil(OrganizationIdToUuid.get(0))
    end
  end

  def test_func(id) do
    case id do
      1 -> {:ok, %{uuid: "11111111-1111-1111-1111-111111111111"}}
      2 -> {:ok, %{uuid: "22222222-2222-2222-2222-222222222222"}}
      3 -> {:ok, %{uuid: "33333333-3333-3333-3333-333333333333"}}
      _ -> {:error, :not_found, "message"}
    end
  end
end
