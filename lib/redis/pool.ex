defmodule ITKCommon.Redis.Pool do
  @moduledoc """
  Manages a pool of connections to Redis.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @spec init(list) :: no_return
  def init([]) do
    config = Application.get_env(:itk_common, :redis, %{})
    pool_size = Keyword.get(config, :pool_size, 10)
    max_overflow = Keyword.get(config, :max_overflow, 5)
    host = Keyword.fetch!(config, :host)

    pool_opts = [
      name: {:local, :redis_pool},
      worker_module: Redix,
      size: pool_size,
      max_overflow: max_overflow
    ]

    children = [
      :poolboy.child_spec(:redis_pool, pool_opts, host)
    ]

    supervise(children, strategy: :one_for_one, name: __MODULE__)
  end
end
