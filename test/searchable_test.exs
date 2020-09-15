defmodule ITKCommon.SearchableTest do
  use ExUnit.Case

  alias ITKCommon.Searchable

  defmodule Basic do
    use Ecto.Schema

    schema "users" do
      field(:uuid, :string)
      field(:first_name, :string)
      field(:last_name, :string)
      field(:active, :boolean)
      field(:start_date, :utc_datetime_usec)
      field(:age, :integer)
    end
  end

  describe "build/2" do
    test "builds query with simple parameters" do
      time = DateTime.from_unix!(1_500_000_000)

      assert %{
               page: 1,
               status: :pending,
               queryable: query,
               filters: %{first_name: "grady", last_name: "griffin"},
               per_page: nil,
               sort_field: nil,
               sort_order: nil
             } =
               Searchable.build(Basic, %{
                 "first_name" => "grady",
                 "last_name" => "griffin",
                 "start_date" => time,
                 "age" => 30
               })

      assert inspect(query) =~ ~r/ilike\(b0.first_name, \^"%grady%"\)/
      assert inspect(query) =~ ~r/ilike\(b0.last_name, \^"%griffin%"\)/
      assert inspect(query) =~ ~r/b0.start_date in \^\[#DateTime<2017-07-14 02:40:00Z>\]/
      assert inspect(query) =~ ~r/b0.age in \^\[30\]/
    end

    test "uses like for simple parameters only if source type is a string" do
      time = DateTime.from_unix!(1_500_000_000)
      time = DateTime.to_iso8601(time)

      assert %{queryable: query} =
               Searchable.build(Basic, %{
                 "start_date" => time
               })

      assert inspect(query) =~ ~r/b0.start_date in \^\["2017-07-14T02:40:00Z"\]/
    end

    test "builds query with eq nil" do
      %{queryable: query} = Searchable.build(Basic, %{"first_name" => %{"eq" => nil}})
      assert inspect(query) =~ ~r/is_nil\(b0.first_name\)/
    end

    test "builds query with eq" do
      %{queryable: query} = Searchable.build(Basic, %{"first_name" => %{"eq" => "grady"}})
      assert inspect(query) =~ ~r/b0.first_name in \^\["grady"\]/
    end

    test "builds query with like" do
      %{queryable: query} = Searchable.build(Basic, %{"first_name" => %{"like" => "grady"}})
      assert inspect(query) =~ ~r/ilike\(b0.first_name, \^"%grady%"\)/
    end

    test "builds query with contains" do
      %{queryable: query} = Searchable.build(Basic, %{"first_name" => %{"contains" => "grady"}})
      assert inspect(query) =~ ~r/ilike\(b0.first_name, \^"%grady%"\)/
    end

    test "builds query with starts_with" do
      %{queryable: query} =
        Searchable.build(Basic, %{"first_name" => %{"starts_with" => "grady"}})

      assert inspect(query) =~ ~r/ilike\(b0.first_name, \^"grady%"\)/
    end

    test "builds query with ends_with" do
      %{queryable: query} = Searchable.build(Basic, %{"first_name" => %{"ends_with" => "grady"}})
      assert inspect(query) =~ ~r/ilike\(b0.first_name, \^"%grady"\)/
    end

    test "builds query with is" do
      %{queryable: query} = Searchable.build(Basic, %{"active" => %{"is" => true}})
      assert inspect(query) =~ ~r/b0.active == true/
      %{queryable: query} = Searchable.build(Basic, %{"active" => %{"is" => false}})
      assert inspect(query) =~ ~r/b0.active == false/
      %{queryable: query} = Searchable.build(Basic, %{"active" => %{"is" => nil}})
      assert inspect(query) =~ ~r/is_nil\(b0.active\)/
    end

    test "is query only allows nil true false" do
      assert_raise RuntimeError, fn ->
        Searchable.build(Basic, %{"active" => %{"is" => 5}})
      end
    end

    test "builds query with is_not" do
      %{queryable: query} = Searchable.build(Basic, %{"active" => %{"is_not" => true}})
      assert inspect(query) =~ ~r/is_nil\(b0.active\) or b0.active == false/
      %{queryable: query} = Searchable.build(Basic, %{"active" => %{"is_not" => false}})
      assert inspect(query) =~ ~r/is_nil\(b0.active\) or b0.active == true/
      %{queryable: query} = Searchable.build(Basic, %{"active" => %{"is_not" => nil}})
      assert inspect(query) =~ ~r/not\(is_nil\(b0.active\)\)/
    end

    test "is_not query only allows nil true false" do
      assert_raise RuntimeError, fn ->
        Searchable.build(Basic, %{"active" => %{"is_not" => 5}})
      end
    end

    test "builds query with in" do
      %{queryable: query} =
        Searchable.build(Basic, %{"first_name" => %{"in" => ["grady", "griffin"]}})

      assert inspect(query) =~ ~r/b0.first_name in \^\["grady", "griffin"\]/
    end

    test "in query only allows a list" do
      assert_raise RuntimeError, fn ->
        Searchable.build(Basic, %{"active" => %{"in" => 5}})
      end
    end

    test "builds query with not_in" do
      %{queryable: query} =
        Searchable.build(Basic, %{"first_name" => %{"not_in" => ["grady", "griffin"]}})

      assert inspect(query) =~ ~r/b0.first_name not in \^\["grady", "griffin"\]/
    end

    test "not_in query only allows a list" do
      assert_raise RuntimeError, fn ->
        Searchable.build(Basic, %{"active" => %{"not_in" => 5}})
      end
    end

    test "builds query with lt" do
      %{queryable: query} = Searchable.build(Basic, %{"age" => %{"lt" => 5}})
      assert inspect(query) =~ ~r/b0.age < \^5/
    end

    test "builds query with lte" do
      %{queryable: query} = Searchable.build(Basic, %{"age" => %{"lte" => 5}})
      assert inspect(query) =~ ~r/b0.age <= \^5/
    end

    test "builds query with gt" do
      %{queryable: query} = Searchable.build(Basic, %{"age" => %{"gt" => 5}})
      assert inspect(query) =~ ~r/b0.age > \^5/
    end

    test "builds query with gte" do
      %{queryable: query} = Searchable.build(Basic, %{"age" => %{"gte" => 5}})
      assert inspect(query) =~ ~r/b0.age >= \^5/
    end

    test "builds query with not nil" do
      %{queryable: query} = Searchable.build(Basic, %{"age" => %{"not" => nil}})
      assert inspect(query) =~ ~r/not\(is_nil\(b0.age\)\)/
    end

    test "builds query with not" do
      %{queryable: query} = Searchable.build(Basic, %{"age" => %{"not" => 5}})
      assert inspect(query) =~ ~r/b0.age != \^5/
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

      assert inspect(query) =~ ~r/ilike\(b0.first_name, \^"%grady%"\)/
      assert inspect(query) =~ ~r/ilike\(b0.last_name, \^"%griffin%"\)/
      assert inspect(query) =~ ~r/order_by: \[desc: \w{2}.last_name\]/
      assert inspect(query) =~ ~r/limit: \^25/
      assert inspect(query) =~ ~r/offset: \^25/
    end
  end
end
