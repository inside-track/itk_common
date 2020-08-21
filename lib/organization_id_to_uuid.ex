defmodule ITKCommon.OrganizationIdToUuid do
  @moduledoc """
  Maps a organization id to uuid
  """

  use ITKCommon.IdToUuid
end

defmodule ITKCommon.Organization_Id_To_Uuid do
  defdelegate get(id), to: ITKCommon.OrganizationIdToUuid
end
