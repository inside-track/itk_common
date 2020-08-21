defmodule ITKCommon.OrganizationIdToUuid do
  @moduledoc """
  Maps a organization id to uuid
  """

  use ITKCommon.IdToUuid
end

defmodule ITKCommon.Organization_Id_To_Uuid do
  @moduledoc """
  Maps a organization id to uuid
  """

  defdelegate get(id), to: ITKCommon.OrganizationIdToUuid
end
