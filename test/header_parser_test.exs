defmodule ITKCommon.HeaderParserTest do
  use ExUnit.Case, async: true

  alias ITKCommon.HeaderParser
  alias ITKCommon.IpLocator
  alias ITKCommon.Thread
  alias Plug.Conn

  describe "call/2" do
    test "stores headers with itk-meta- prefix in process metadata" do
      user_uuid = UUID.uuid4()

      conn =
        build_conn()
        |> Conn.put_req_header("itk-meta-user-uuid", user_uuid)
        |> Conn.put_req_header("itk-meta-user-role", "Tester")

      HeaderParser.call(conn)

      assert %{
               "user_uuid" => ^user_uuid,
               "user_role" => "Tester"
             } = Thread.to_map()
    end

    test "sets mobile_app to Android when user agent contains android" do
      build_conn()
      |> Conn.put_req_header(
        "user-agent",
        "Mozilla/5.0 (Linux; Android 4.0.4; Galaxy Nexus Build/IMM76B) AppleWebKit/535.19"
      )
      |> HeaderParser.call()

      assert %{
               "device_type" => "Android"
             } = Thread.to_map()
    end

    test "sets current_mobile_app to iOS when user agent contains ios" do
      build_conn()
      |> Conn.put_req_header(
        "user-agent",
        "Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_4 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10B350 Safari/8536.25"
      )
      |> HeaderParser.call()

      assert %{
               "device_type" => "iOS"
             } = Thread.to_map()
    end

    test "sets app version" do
      build_conn()
      |> Conn.put_req_header("app-version", "0.0.1")
      |> HeaderParser.call()

      assert %{
               "app_version" => "0.0.1"
             } = Thread.to_map()
    end

    test "sets os version" do
      build_conn()
      |> Conn.put_req_header("os-version", "0.0.1")
      |> HeaderParser.call()

      assert %{
               "os_version" => "0.0.1"
             } = Thread.to_map()
    end

    test "sets ip" do
      build_conn()
      |> Conn.put_req_header("x-forwarded-for", "1.0.0.1")
      |> HeaderParser.call()

      assert %{
               "ip" => "1.0.0.1"
             } = Thread.to_map()
    end

    test "sets ip_location" do
      IpLocator.block_invalid()

      build_conn()
      |> Conn.put_req_header("x-forwarded-for", "1.0.0.1")
      |> HeaderParser.call()

      assert %{
               "ip_location" => "ZZ"
             } = Thread.to_map()

      IpLocator.clear()
    end

    test "sets default ip_location" do
      build_conn()
      |> HeaderParser.call()

      assert %{
               "ip_location" => "INVALID"
             } = Thread.to_map()
    end
  end

  defp build_conn do
    %Conn{}
  end
end
