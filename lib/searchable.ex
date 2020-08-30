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
            sort_order: nil

  defmacro __using__(opts) do
    repo = Keyword.get(opts, :repo)
    sort_field = Keyword.get(opts, :sort_field)
    per_page = Keyword.get(opts, :per_page)

    sort_order =
      case {sort_field, Keyword.get(opts, :sort_order)} do
        {nil, _} -> nil
        {_, nil} -> :asc
        {_, v} -> v
      end

    fields =
      opts
      |> Keyword.get(:fields, [])
      |> List.wrap()
      |> Enum.reduce([], fn item, acc ->
        cond do
          is_atom(item) ->
            [to_string(item) | acc]

          is_binary(item) ->
            [item | acc]

          true ->
            acc
        end
      end)

    quote generated: true do
      use Ecto.Schema

      def build_searchable(filters) do
        ITKCommon.Searchable.build(__MODULE__, filters, [])
      end

      def build_searchable(filters, options) do
        ITKCommon.Searchable.build(__MODULE__, filters, options)
      end

      def search(filters, options) when is_map(filters) and is_list(options) do
        filters
        |> build_searchable(options)
        |> ITKCommon.Searchable.search(unquote(repo))
      end

      def search(searchable = %ITKCommon.Searchable{}, repo) do
        ITKCommon.Searchable.search(searchable, repo)
      end

      def itk_common_searchable_fields do
        unquote(fields)
      end

      def itk_common_searchable_default(filters) do
        {field, order} =
          if unquote(sort_field) in __MODULE__.__schema__(:fields) do
            {nil, nil}
          else
            {unquote(sort_field), unquote(sort_order)}
          end

        field =
          if is_binary(field) do
            String.to_atom(field)
          else
            field
          end

        %ITKCommon.Searchable{
          queryable: __MODULE__,
          per_page: unquote(per_page),
          sort_field: field,
          sort_order: order,
          filters: filters
        }
      end
    end
  end

  def build(mod, filters, options) do
    filters =
      filters
      |> restrict_to_specified(mod.itk_common_searchable_fields())
      |> ITKCommon.Utils.Map.atomize_keys()
      |> Map.take(mod.__schema__(:fields))

    mod.itk_common_searchable_default(filters)
    |> add_options(mod, options)
    |> apply_filters()
    |> apply_sorting()
    |> apply_pagination()
  end

  def search(searchable = %{status: :pending}, repo) do
    result = repo.all(searchable)

    %{
      searchable
      | result: result,
        status: :ok
    }
  end

  def search(searchable, _repo) do
    searchable
  end

  defp apply_filters(struct) do
    query =
      Enum.reduce(struct.filters, struct.queryable, fn filter, query ->
        apply_filter(filter, query)
      end)

    %{struct | queryable: query}
  end

  defp apply_filter({field, value}, query) when not is_map(value) do
    value = List.wrap(value)
    where(query, [x], field(x, ^field) in ^value)
  end

  def add_options(struct, _mod, []) do
    struct
  end

  def add_options(struct, mod, [{:sort_field, field} | tl]) do
    if field in mod.__schema__(:fields) do
      struct
      |> Map.merge(%{sort_field: field})
      |> add_options(mod, tl)
    else
      add_options(struct, mod, tl)
    end
  end

  def add_options(struct, mod, [{:per_page, per_page} | tl]) do
    struct
    |> Map.merge(%{per_page: per_page})
    |> add_options(mod, tl)
  end

  def add_options(struct, mod, [{:page, page} | tl]) do
    struct
    |> Map.merge(%{page: page})
    |> add_options(mod, tl)
  end

  def add_options(struct, mod, [{:sort_order, order} | tl]) do
    order =
      if order in [:desc, "desc"] do
        :desc
      else
        :asc
      end

    struct
    |> Map.merge(%{sort_order: order})
    |> add_options(mod, tl)
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

  defp apply_sorting(struct = %{sort_field: nil}) do
    struct
  end

  defp apply_sorting(struct) do
    query = order_by(struct.queryable, [x], [{^struct.sort_order, ^struct.sort_field}])

    %{struct | queryable: query}
  end

  defp restrict_to_specified(filter, []) do
    filter
  end

  defp restrict_to_specified(filter, specified) do
    Map.take(filter, specified)
  end
end
