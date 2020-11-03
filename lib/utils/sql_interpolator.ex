defmodule ITKCommon.Utils.SqlInterpolator do
  @moduledoc """
  Convert an ecto query to interpolated sql
  """

  def from_string({string, args}) do
    l = length(args)

    args
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce(string, fn {a, i}, acc ->
      idx = l - i

      String.replace(acc, "$#{idx}", interpolate(a))
    end)
  end

  def from_ecto(repo, query) do
    :all
    |> repo.to_sql(query)
    |> from_string()
  end

  defp interpolate(nil) do
    "NULL"
  end

  defp interpolate(v = %DateTime{}) do
    v
    |> Timex.format!("{YYYY}-{0M}-{0D} {0h24}:{m}:{s}{ss}")
    |> interpolate()
  end

  defp interpolate(v) when is_binary(v) do
    "'#{v}'"
  end

  defp interpolate(v) when is_number(v) do
    "#{v}"
  end

  defp interpolate(v) when is_list(v) do
    interpolate([], v)
  end

  defp interpolate(acc, []) do
    "ARRAY[" <> Enum.join(acc, ", ") <> "]"
  end

  defp interpolate(acc, [hd | tl]) do
    interpolate([interpolate(hd) | acc], tl)
  end
end
