defmodule ITKCommon.Features do
  @moduledoc """
  Module to normalize and encapsulate feature flag functionality
  """
  use ITKCommon.RedisCache

  alias ITKCommon.Utils.Text

  @off_value "off"
  @off_values [@off_value, nil]

  def on?(name) do
    not off?(name)
  end

  def on!(name) do
    set(name, Text.iso8601_now())
  end

  def off?(name) do
    name
    |> redis_get()
    |> (&(&1 in @off_values)).()
  end

  def off!(name) do
    redis_set(name, @off_value)
  end

  def del(name) do
    redis_del(name)
  end

  def set(_name, @off_value) do
    raise "#{@off_value} is not an allowed value."
  end

  def set(name, value) do
    redis_set(name, value)
  end

  def all do
    redis_get_all()
  end

  def eq?(name, other) do
    compare(name, other, [:eq])
  end

  def gt?(name, other) do
    compare(name, other, [:gt])
  end

  def lt?(name, other) do
    compare(name, other, [:lt])
  end

  def gte?(name, other) do
    compare(name, other, [:eq, :gt])
  end

  def lte?(name, other) do
    compare(name, other, [:eq, :lt])
  end

  defp compare(name, other, ops) do
    other = to_string(other)
    value = redis_get(name)

    cond do
      value in @off_values ->
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
