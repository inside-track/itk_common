defmodule ITKCommon.SOCToCIP do
  @moduledoc false

  use Agent

  def start_link(_) do
    Agent.start_link(&load_data/0, name: __MODULE__)
  end

  @spec get(soc_codes :: String.t() | list(String.t())) :: list(String.t())
  def get(cip_codes) do
    cip_codes
    |> get_majors()
    |> Enum.map(&elem(&1, 0))
    |> Enum.uniq()
  end

  @spec get_majors(soc_codes :: String.t() | list(String.t())) :: list({String.t(), String.t()})
  def get_majors(soc_codes) do
    soc_codes
    |> do_get()
    |> Enum.uniq()
  end

  defp do_get(soc_codes) do
    soc_codes
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
      cip_title = Map.get(row, "CIP2010Title")
      cip_definition = Map.get(row, "CIP2010Definition")

      list = Map.get(map, soc_code, [])
      Map.put(map, soc_code, [{cip_code, cip_title, cip_definition} | list])
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
