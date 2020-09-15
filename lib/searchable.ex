defmodule ITKCommon.Searchable do
  @moduledoc """
  Handles searching for records in database.
  """
  import Ecto.Query

  defstruct result: [],
            page: 1,
            status: :pending,
            queryable: nil,
            filters: nil,
            per_page: nil,
            sort_field: nil,
            sort_order: nil,
            ecto_schema: nil

  def build(queryable, filters, options \\ []) do
    mod = first_binding(queryable)
    allowable = fields(mod)

    %__MODULE__{
      queryable: queryable,
      ecto_schema: mod
    }
    |> add_options(options)
    |> apply_filters(filters, allowable)
    |> apply_sorting(allowable)
    |> apply_pagination()
  end

  def search(searchable = %__MODULE__{status: :pending}, repo) do
    result = repo.all(searchable)

    %{
      searchable
      | result: result,
        status: :ok
    }
  end

  def search(queryable, filters, repo) do
    search(queryable, filters, repo, [])
  end

  def search(searchable, filters, repo, options) when is_map(filters) and is_list(options) do
    searchable
    |> build(filters, options)
    |> search(repo)
  end

  defp apply_filters(struct, filters, allowable) do
    {query, filters} =
      Enum.reduce(filters, {struct.queryable, %{}}, fn {field, value}, {query, filters} ->
        case validate(field, allowable) do
          nil ->
            {query, filters}

          field ->
            {
              apply_filter(field, value, query),
              Map.put(filters, field, value)
            }
        end
      end)

    %{struct | queryable: query, filters: filters}
  end

  defp apply_filter(field, value, query) when not is_map(value) do
    value =
      value
      |> List.wrap()
      |> Enum.reject(&is_nil/1)

    where(query, [x], field(x, ^field) in ^value)
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
        query = order_by(struct.queryable, [x], [{^struct.sort_order, ^field}])

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
