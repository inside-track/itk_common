defmodule ITKCommon.Features do
  use ITKCommon.RedisCache

  alias ITKCommon.Utils.Text

  def on?(name) do
    name
    |> redis_get()
    |> is_binary()
  end

  def on!(name) do
    set(name, Text.iso8601_now())
  end

  def off?(name) do
    not on?(name)
  end

  def off!(name) do
    redis_del(name)
  end

  def set(key, value) do
    redis_set(key, value)
  end

  def all do
    redis_get_all()
  end

  def eq?(key, other) do
    compare(key, other, [:eq])
  end

  def gt?(key, other) do
    compare(key, other, [:gt])
  end

  def lt?(key, other) do
    compare(key, other, [:lt])
  end

  def gte?(key, other) do
    compare(key, other, [:eq, :gt])
  end

  def lte?(key, other) do
    compare(key, other, [:eq, :lt])
  end

  defp compare(key, other, ops) do
    other = to_string(other)
    value = redis_get(key)

    cond do
      is_nil(value) ->
        false

      :eq in ops and value == other ->
        true

      :gt in ops ->
        value > other

      true ->
        value < other
    end
  end
end
