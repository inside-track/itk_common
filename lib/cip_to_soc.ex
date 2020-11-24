defmodule ITKCommon.CIPToSOC do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(&load_data/0, name: __MODULE__)
  end

  @spec get(cip_codes :: String.t() | list(String.t())) :: list(String.t())
  def get(cip_codes) do
    cip_codes
    |> get_careers()
    |> Enum.map(&elem(&1, 0))
    |> Enum.uniq()
  end

  @spec get_careers(cip_codes :: String.t() | list(String.t())) ::
          list({String.t(), String.t(), String.t()})
  def get_careers(cip_codes) do
    cip_codes
    |> do_get()
    |> Enum.uniq()
  end

  defp do_get(cip_codes) do
    cip_codes
    |> List.wrap()
    |> Enum.flat_map(fn code ->
      Agent.get(__MODULE__, &Map.get(&1, code, []))
    end)
  end

  defp load_data do
    load_path()
    |> File.stream!([:compressed])
    |> CSV.decode!(strip_fields: true, headers: true)
    |> Enum.reduce(%{}, fn row, map ->
      soc_code = Map.get(row, "SOC2010Code")
      cip_code = Map.get(row, "CIP2010Code")
      soc_title = Map.get(row, "SOC2010Title")

      list = Map.get(map, cip_code, [])
      Map.put(map, cip_code, [{soc_code, soc_title} | list])
    end)
  end

  defp data_directory do
    priv_dir = :itk_common |> :code.priv_dir() |> to_string

    :itk_common
    |> Application.get_env(:soc_to_cip, [])
    |> Keyword.get(:data_directory, priv_dir)
  end

  defp load_path do
    Path.join([data_directory(), "soc_to_cip", "data.csv.gz"])
  end
end
