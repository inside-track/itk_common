defmodule ITKCommon.Utils.Text do
  @moduledoc """
  Utilities for interacting with text.
  """

  @doc """
  Sanitizes text.
  Removes invalid unicode characters.
  """
  @spec sanitize(text :: String.t()) :: String.t()
  def sanitize(text) do
    text |> IO.iodata_to_binary() |> String.replace("\u0000", "")
  end

  def address_titleize(text) do
    text
    |> String.split(~r[\s+])
    |> Enum.map(fn v ->
      if v in ~w[NE NW SE SW] do
        v
      else
        String.capitalize(v)
      end
    end)
    |> Enum.join(" ")
  end

  def is_uuid?(text) when is_binary(text) do
    ~r/[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}/
    |> Regex.match?(text)
  end

  def is_uuid?(charlist) when is_list(charlist) do
    charlist
    |> to_string
    |> is_uuid?
  end

  def is_uuid?(_), do: false

  def iso8601_now do
    iso8601_now(milliseconds: 0)
  end

  def iso8601_now(options) do
    Timex.shift(DateTime.utc_now(), options)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  def printable(word) do
    if Regex.match?(~r/[^ -~]/, word) do
      word
      |> String.codepoints()
      |> Enum.map_join(fn p ->
        if String.printable?(p) do
          p
        else
          " "
        end
      end)
      |> String.replace(~r/\s+/, " ")
    else
      word
    end
  end

  def format_zip(zip) do
    cond do
      String.length(zip) > 4 ->
        String.slice(zip, 0..4)

      String.length(zip) < 5 ->
        String.pad_leading(zip, 5, "0")

      true ->
        nil
    end
  end
end
