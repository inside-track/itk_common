defmodule ITKCommon.Utils.TitleSlug do
  @moduledoc """
  Utilities for generating title slugs text.
  """

  @non_alphanumeric_regex ~r/[^a-zA-Z0-9]+/

  @doc """
  Generate a slug from a string
  Just replace non alphanumeric characters by hyphens and downcase all letters
  """
  @spec generate(string :: String.t()) :: String.t()
  def generate(string) when is_binary(string) do
    string
    |> String.replace(@non_alphanumeric_regex, "-")
    |> String.trim("-")
    |> String.downcase()
  end

  def generate(string), do: string
end
