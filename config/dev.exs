use Mix.Config

config :itk_common,
  env: Mix.env(),
  running_library_tests: true

config :itk_common, :redis, host: System.get_env("REDIS_URL") || "redis://localhost:6379"
