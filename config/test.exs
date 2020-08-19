use Mix.Config

config :itk_common,
  env: Mix.env(),
  running_library_tests: true

config :itk_common, :redis, host: System.get_env("REDIS_URL") || "redis://localhost:6379"

config :itk_common, ITKCommon.OrganizationIdToUuid, [
  ITKCommon.OrganizationIdToUuidTest,
  :test_func
]

config :itk_queue,
  amqp_url: System.get_env("AMQP_URL") || "amqp://localhost:5672",
  amqp_exchange: "test",
  use_atom_keys: false,
  fallback_endpoint: false,
  max_retries: 10,
  env: :test

config :itk_queue, ITK.QueueMiddleware.TransactionMetadata, enabled: false

config :itk_common, :ip_locator, data_directory: "test/support"
config :itk_common, :zip_geolocation, data_directory: "test/support"
