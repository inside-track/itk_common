defmodule ITKCommon.Id_To_Uuid.Util do
  @moduledoc """
  Module to map an ids to uuids
  """

  def error_func(_) do
    raise "No source function defined"
  end

  def get(client_mod, id, mod, func) do
    client_mod
    |> check_for_ets_table()
    |> get_uuid_from_cache(client_mod, id)
    |> get_uuid_from_source(id, mod, func)
  end

  defp check_for_ets_table(client_mod) do
    :ets.whereis(client_mod)
  end

  defp get_uuid_from_cache(:undefined, client_mod, _id) do
    :ets.new(client_mod, [:set, :named_table, :public])
  end

  defp get_uuid_from_cache(ref, _client_mod, id) do
    case :ets.lookup(ref, id) do
      [] -> ref
      [{_id, uuid} | _] -> uuid
    end
  end

  defp get_uuid_from_source(uuid, _id, _mod, _func) when is_binary(uuid) do
    uuid
  end

  defp get_uuid_from_source(ref, id, mod, func) do
    mod
    |> apply(func, [id])
    |> case do
      {:ok, %{uuid: uuid}} ->
        :ets.insert(ref, {id, uuid})
        uuid

      _ ->
        nil
    end
  end
end
