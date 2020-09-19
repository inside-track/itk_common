defmodule ITKCommon.Searchable do
  @moduledoc """
  Handles searching for records in database.
  """
  import Ecto.Query

  @type t :: %__MODULE__{
          page: integer,
          status: atom,
          queryable: Ecto.Queryable.t() | nil,
          filters: nil,
          per_page: integer | nil,
          sort_field: atom | nil,
          sort_order: atom | nil,
          ecto_schema: Ecto.Queryable.t() | nil
        }

  defstruct items: [],
            page: 1,
            status: :pending,
            queryable: nil,
            filters: nil,
            per_page: nil,
            sort_field: nil,
            sort_order: nil,
            ecto_schema: nil

  @spec build(queryable :: Ecto.Queryable.t(), filters :: list(map) | map, option :: list) :: t()
  def build(queryable, filters, options \\ []) do
    mod = first_binding(queryable)
    allowable = fields(mod)

    %__MODULE__{
      queryable: queryable,
      ecto_schema: mod
    }
    |> add_options(options)
    |> apply_filters(filters, allowable, mod)
    |> apply_sorting(allowable)
    |> apply_pagination()
  end

  @spec search(searchable :: t(), repo :: atom) :: t
  def search(searchable = %__MODULE__{status: :pending}, repo) do
    result = repo.all(searchable.queryable)

    %{
      searchable
      | items: result,
        status: :ok
    }
  end

  def search(queryable, filters, repo) do
    search(queryable, filters, repo, [])
  end

  def search(searchable, filters, repo, options) do
    searchable
    |> build(filters, options)
    |> search(repo)
  end

  defp apply_filters(struct, filters, allowable, mod) when is_map(filters) do
    {query, filters} =
      Enum.reduce(filters, {struct.queryable, %{}}, fn {field, value}, {query, filters} ->
        case validate(field, allowable) do
          nil ->
            {query, filters}

          field ->
            {
              apply_filter(field, value, query, mod),
              Map.put(filters, field, value)
            }
        end
      end)

    %{struct | queryable: query, filters: filters}
  end

  defp apply_filters(struct, filters, allowable, mod) when is_list(filters) do
    filters =
      Enum.reduce(filters, %{}, fn filter, acc ->
        field =
          filter
          |> Map.keys()
          |> List.first()

        Map.put(acc, field, filter[field])
      end)

    apply_filters(struct, filters, allowable, mod)
  end

  defp apply_filter(field, value, query, mod) do
    cond do
      is_map(value) ->
        apply_filter(field, value, query)

      is_binary(value) and mod.__schema__(:type, field) == :string ->
        apply_filter(field, %{"fuzzy" => value}, query)

      true ->
        apply_filter(field, %{"eq" => value}, query)
    end
  end

  defp apply_filter(field, %{"eq" => nil}, query) do
    apply_filter(field, %{"is" => nil}, query)
  end

  defp apply_filter(field, %{"eq" => value}, query) do
    value =
      value
      |> List.wrap()
      |> Enum.reject(&is_nil/1)

    apply_filter(field, %{"in" => value}, query)
  end

  defp apply_filter(field, %{"contains" => value}, query) do
    apply_filter(field, %{"like" => value}, query)
  end

  defp apply_filter(field, %{"fuzzy" => value}, query) when is_binary(value) do
    regex =
      value
      |> String.split(~r/\s+/, trim: true)
      |> Enum.reject(fn x -> String.length(x) < 3 end)
      |> Enum.join("|")

    where(query, [x], fragment("? ~* ?", field(x, ^field), ^regex))
  end

  defp apply_filter(field, %{"fuzzy" => value}, query) do
    apply_filter(field, %{"eq" => value}, query)
  end

  defp apply_filter(field, %{"like" => value}, query) do
    apply_like(field, "%", value, "%", query)
  end

  defp apply_filter(field, %{"starts_with" => value}, query) do
    apply_like(field, "", value, "%", query)
  end

  defp apply_filter(field, %{"ends_with" => value}, query) do
    apply_like(field, "%", value, "", query)
  end

  defp apply_filter(_field, %{"lt" => nil}, query) do
    where(query, [x], false)
  end

  defp apply_filter(field, %{"lt" => value}, query) do
    where(query, [x], field(x, ^field) < ^value)
  end

  defp apply_filter(_field, %{"lte" => nil}, query) do
    where(query, [x], false)
  end

  defp apply_filter(field, %{"lte" => value}, query) do
    where(query, [x], field(x, ^field) <= ^value)
  end

  defp apply_filter(_field, %{"gt" => nil}, query) do
    where(query, [x], false)
  end

  defp apply_filter(field, %{"gt" => value}, query) do
    where(query, [x], field(x, ^field) > ^value)
  end

  defp apply_filter(_field, %{"gte" => nil}, query) do
    where(query, [x], false)
  end

  defp apply_filter(field, %{"gte" => value}, query) do
    where(query, [x], field(x, ^field) >= ^value)
  end

  defp apply_filter(field, %{"not" => nil}, query) do
    apply_filter(field, %{"is_not" => nil}, query)
  end

  defp apply_filter(field, %{"not" => value}, query) do
    where(query, [x], field(x, ^field) != ^value)
  end

  defp apply_filter(field, %{"in" => value}, query) when is_list(value) do
    where(query, [x], field(x, ^field) in ^value)
  end

  defp apply_filter(_field, %{"in" => _}, _query) do
    raise "Use `in` only when checking for membership in a list"
  end

  defp apply_filter(field, %{"not_in" => value}, query) when is_list(value) do
    where(query, [x], field(x, ^field) not in ^value)
  end

  defp apply_filter(_field, %{"not_in" => _}, _query) do
    raise "Use `not_in` only when checking for membership in a list"
  end

  defp apply_filter(field, %{"is" => true}, query) do
    where(query, [x], field(x, ^field) == true)
  end

  defp apply_filter(field, %{"is" => false}, query) do
    where(query, [x], field(x, ^field) == false)
  end

  defp apply_filter(field, %{"is" => nil}, query) do
    where(query, [x], is_nil(field(x, ^field)))
  end

  defp apply_filter(_field, %{"is" => _}, _query) do
    raise "Use `is` only when comparing nil, false or true"
  end

  defp apply_filter(field, %{"is_not" => true}, query) do
    where(query, [x], is_nil(field(x, ^field)) or field(x, ^field) == false)
  end

  defp apply_filter(field, %{"is_not" => false}, query) do
    where(query, [x], is_nil(field(x, ^field)) or field(x, ^field) == true)
  end

  defp apply_filter(field, %{"is_not" => nil}, query) do
    where(query, [x], not is_nil(field(x, ^field)))
  end

  defp apply_filter(_field, %{"is_not" => _}, _query) do
    raise "Use `is_not` only when comparing nil, false or true"
  end

  defp apply_filter(field, value, query) do
    apply_filter(field, %{"eq" => value}, query)
  end

  defp apply_like(field, a, value, z, query) when is_binary(value) do
    like_text = a <> value <> z
    where(query, [x], ilike(field(x, ^field), ^like_text))
  end

  defp apply_like(_field, _, _value, _, query) do
    where(query, [x], false)
  end

  defp add_options(struct, []) do
    struct
  end

  defp add_options(struct, [{:sort_field, field} | tl]) do
    struct
    |> Map.merge(%{sort_field: field})
    |> add_options(tl)
  end

  defp add_options(struct, [{:per_page, per_page} | tl]) do
    struct
    |> Map.merge(%{per_page: per_page})
    |> add_options(tl)
  end

  defp add_options(struct, [{:page, page} | tl]) do
    struct
    |> Map.merge(%{page: page})
    |> add_options(tl)
  end

  defp add_options(struct, [{:sort_order, order} | tl]) do
    order =
      if order in [:desc, "desc"] do
        :desc
      else
        :asc
      end

    struct
    |> Map.merge(%{sort_order: order})
    |> add_options(tl)
  end

  defp apply_pagination(struct = %{per_page: per_page}) when is_integer(per_page) do
    offset = (struct.page - 1) * per_page

    query =
      struct.queryable
      |> Ecto.Query.offset(^offset)
      |> Ecto.Query.limit(^per_page)

    %{struct | queryable: query}
  end

  defp apply_pagination(struct), do: struct

  defp apply_sorting(struct = %{sort_field: nil}, _) do
    struct
  end

  defp apply_sorting(struct, allowable) do
    case validate(struct.sort_field, allowable) do
      nil ->
        struct

      field ->
        order = Map.get(struct, :sort_order, :asc)
        query = order_by(struct.queryable, [x], [{^order, ^field}])

        %{struct | queryable: query}
    end
  end

  defp fields(mod) do
    fields = mod.__schema__(:fields)

    {Enum.map(fields, &to_string/1), fields}
  end

  defp first_binding(queryable) when is_atom(queryable) do
    :functions
    |> queryable.__info__()
    |> Keyword.has_key?(:__schema__)
    |> case do
      false -> first_binding(nil)
      _ -> queryable
    end
  end

  defp first_binding(%{from: %{source: {_, mod}}}) when not is_nil(mod) do
    first_binding(mod)
  end

  defp first_binding(_) do
    raise "Invalid query, the first binding most be Ecto.Schema"
  end

  defp validate(key, {strings, atoms}) do
    cond do
      is_atom(key) and key in atoms ->
        key

      is_binary(key) and key in strings ->
        String.to_atom(key)

      true ->
        nil
    end
  end
end
