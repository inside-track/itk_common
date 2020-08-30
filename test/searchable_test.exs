defmodule ITKCommon.SearchableTest do
  use ExUnit.Case

  defmodule Basic do
    use ITKCommon.Searchable,
      fields: [
        :first_name,
        :last_name,
        :unknown
      ]

    schema "users" do
      field(:uuid, :string)
      field(:first_name, :string)
      field(:last_name, :string)
      field(:start_date, :utc_datetime_usec)
      field(:age, :integer)
    end
  end

  defmodule Options do
    use ITKCommon.Searchable,
      per_page: 50,
      sort_field: "first_name"

    schema "users" do
      field(:uuid, :string)
      field(:first_name, :string)
      field(:last_name, :string)
      field(:start_date, :utc_datetime_usec)
      field(:age, :integer)
    end
  end

  describe "build_searchable/1" do
    test "builds query with simple parameters" do
      assert %{
               page: 1,
               status: :pending,
               queryable: query,
               filters: %{first_name: "grady", last_name: "griffin"},
               per_page: nil,
               sort_field: nil,
               sort_order: nil
             } = Basic.build_searchable(%{"first_name" => "grady", "last_name" => "griffin"})

      assert inspect(query) =~ ~r/first_name in \^\["grady"\]/
      assert inspect(query) =~ ~r/last_name in \^\["griffin"\]/
    end

    test "does not allow unspecified fields" do
      assert %{
               page: 1,
               status: :pending,
               queryable: query,
               filters: %{first_name: "grady"},
               per_page: nil,
               sort_field: nil,
               sort_order: nil
             } = Basic.build_searchable(%{"first_name" => "grady", "uuid" => "abc"})

      refute inspect(query) =~ ~r/uuid in \^\["abc"\]/
    end

    test "does not allow specified fields that are not schema fields" do
      assert %{
               page: 1,
               status: :pending,
               queryable: query,
               filters: %{first_name: "grady"},
               per_page: nil,
               sort_field: nil,
               sort_order: nil
             } = Basic.build_searchable(%{"first_name" => "grady", "unknown" => "abc"})

      refute inspect(query) =~ ~r/unknown in \^\["abc"\]/
    end

    test "includes default options" do
      assert %{
               page: 1,
               status: :pending,
               queryable: query,
               filters: %{first_name: "grady", last_name: "griffin"},
               per_page: 50,
               sort_field: :first_name,
               sort_order: :asc
             } = Options.build_searchable(%{"first_name" => "grady", "last_name" => "griffin"})

      assert inspect(query) =~ ~r/first_name in \^\["grady"\]/
      assert inspect(query) =~ ~r/last_name in \^\["griffin"\]/
      assert inspect(query) =~ ~r/order_by: \[asc: \w{2}.first_name\]/
      assert inspect(query) =~ ~r/limit: \^50/
      assert inspect(query) =~ ~r/offset: \^0/
    end
  end

  describe "build_searchable/2" do
    test "overrides default options" do
      assert %{
               status: :pending,
               queryable: query,
               filters: %{first_name: "grady", last_name: "griffin"},
               per_page: 25,
               sort_field: :last_name,
               sort_order: :desc,
               page: 2
             } =
               Options.build_searchable(%{"first_name" => "grady", "last_name" => "griffin"},
                 per_page: 25,
                 sort_field: :last_name,
                 sort_order: :desc,
                 page: 2
               )

      assert inspect(query) =~ ~r/first_name in \^\["grady"\]/
      assert inspect(query) =~ ~r/last_name in \^\["griffin"\]/
      assert inspect(query) =~ ~r/order_by: \[desc: \w{2}.last_name\]/
      assert inspect(query) =~ ~r/limit: \^25/
      assert inspect(query) =~ ~r/offset: \^25/
    end
  end
end
