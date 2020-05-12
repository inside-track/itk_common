use Mix.Config

config :itk_common,
  env: Mix.env(),
  running_library_tests: true

config :itk_common, :redis, host: System.get_env("REDIS_URL") || "redis://localhost:6379"

config :itk_common, ITKCommon.Organization_Id_To_Uuid, [
  ITKCommon.Organization_Id_To_UuidTest,
  :test_func
]
