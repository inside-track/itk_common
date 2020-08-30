defmodule ITKCommon.Events do
  @moduledoc """
  Handles event tracking.
  """

  defdelegate capture(data, user_or_session_or_token),
    to: ITKCommon.Interactions,
    as: :capture_event
end
