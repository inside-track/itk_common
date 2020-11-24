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

  describe "get_majors/1" do
    test "looking up majors by string" do
      assert SOCToCIP.get_majors("11-1011") == [
               {"52.0101", "Business/Commerce, General.",
                "A program that focuses on the general study of business, including the processes of interchanging goods and services (buying, selling and producing), business organization, and accounting as used in profit-making and nonprofit public and private institutions and agencies.  The programs may prepare individuals to apply business principles and techniques in various occupational settings."},
               {"44.0401", "Public Administration.",
                "A program that prepares individuals to serve as managers in the executive arm of local, state, and federal government and that focuses on the systematic study of executive organization and management.  Includes instruction in the roles, development, and principles of public administration; the management of public policy; executive-legislative relations; public budgetary processes and financial management; administrative law; public personnel management; professional ethics; and research methods."}
             ]

      assert SOCToCIP.get_majors("11-1021") == [
               {"52.0101", "Business/Commerce, General.",
                "A program that focuses on the general study of business, including the processes of interchanging goods and services (buying, selling and producing), business organization, and accounting as used in profit-making and nonprofit public and private institutions and agencies.  The programs may prepare individuals to apply business principles and techniques in various occupational settings."},
               {"44.0401", "Public Administration.",
                "A program that prepares individuals to serve as managers in the executive arm of local, state, and federal government and that focuses on the systematic study of executive organization and management.  Includes instruction in the roles, development, and principles of public administration; the management of public policy; executive-legislative relations; public budgetary processes and financial management; administrative law; public personnel management; professional ethics; and research methods."},
               {"31.0399", "Parks, Recreation and Leisure Facilities Management, Other.",
                "Any instructional program in parks, recreation and leisure facilities management not listed above."}
             ]
    end

    test "looking up majors by list" do
      assert SOCToCIP.get_majors(["11-1021", "11-1011"]) == [
               {"52.0101", "Business/Commerce, General.",
                "A program that focuses on the general study of business, including the processes of interchanging goods and services (buying, selling and producing), business organization, and accounting as used in profit-making and nonprofit public and private institutions and agencies.  The programs may prepare individuals to apply business principles and techniques in various occupational settings."},
               {"44.0401", "Public Administration.",
                "A program that prepares individuals to serve as managers in the executive arm of local, state, and federal government and that focuses on the systematic study of executive organization and management.  Includes instruction in the roles, development, and principles of public administration; the management of public policy; executive-legislative relations; public budgetary processes and financial management; administrative law; public personnel management; professional ethics; and research methods."},
               {"31.0399", "Parks, Recreation and Leisure Facilities Management, Other.",
                "Any instructional program in parks, recreation and leisure facilities management not listed above."}
             ]
    end
  end
end
