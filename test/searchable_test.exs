defmodule ITKCommon.SearchableTest do
  use ExUnit.Case

  alias ITKCommon.Searchable

  defmodule Basic do
    use Ecto.Schema

    schema "users" do
      field(:uuid, :string)
      field(:first_name, :string)
      field(:last_name, :string)
      field(:start_date, :utc_datetime_usec)
      field(:age, :integer)
    end
  end

  describe "build/2" do
    test "builds query with simple parameters" do
      assert %{
               page: 1,
               status: :pending,
               queryable: query,
               filters: %{first_name: "grady", last_name: "griffin"},
               per_page: nil,
               sort_field: nil,
               sort_order: nil
             } = Searchable.build(Basic, %{"first_name" => "grady", "last_name" => "griffin"})

      assert inspect(query) =~ ~r/first_name in \^\["grady"\]/
      assert inspect(query) =~ ~r/last_name in \^\["griffin"\]/
    end
  end

  describe "build/3" do
    test "with options" do
      assert %{
               status: :pending,
               queryable: query,
               filters: %{first_name: "grady", last_name: "griffin"},
               per_page: 25,
               sort_field: :last_name,
               sort_order: :desc,
               page: 2
             } =
               Searchable.build(Basic, %{"first_name" => "grady", "last_name" => "griffin"},
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
