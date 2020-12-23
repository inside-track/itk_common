require Logger

defmodule ITKCommon.SpandexTracer do
  @moduledoc false
  use Spandex.Tracer, otp_app: :itk_email
  use Supervisor

  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise("Tracer expects :otp_app to be given")
      Spandex.Tracer.__using__(opts)

      defp get_config do
        config([], @otp_app)
      end
    end
  end

  def start_link(_init_arg) do
    ITKCommon.SpandexTracer.configure(
      disabled?: false,
      adapter: SpandexDatadog.Adapter,
      service: Application.fetch_env!(:itk_common, :service_name),
      env: System.get_env("APPLICATION_ENVIRONMENT") || "dev"
    )

    spandex_opts = [
      host: System.get_env("DATADOG_HOST") || "localhost",
      port: String.to_integer(System.get_env("DATADOG_PORT", "8126")),
      batch_size: String.to_integer(System.get_env("SPANDEX_BATCH_SIZE", "10")),
      sync_threshold: String.to_integer(System.get_env("SPANDEX_SYNC_THRESHOLD", "100")),
      http: HTTPoison,
      verbose?: true
    ]

    Logger.info("Datadog Tracer Options: #{inspect(spandex_opts)}")

    children = [
      %{
        id: SpandexDatadog,
        start: {SpandexDatadog.ApiServer, :start_link, [spandex_opts]}
      }
    ]

    opts = [strategy: :one_for_one, name: ITKCommon.SpandexTracer]
    Supervisor.start_link(children, opts)
  end
end

if Code.ensure_loaded?(Decorator.Define) do
  defmodule ITKCommon.Tracers.SpandexTracer do
    @moduledoc """
    To resolve name conflict with `Spandex.Decorators`.
    """

    @tracer ITKCommon.SpandexTracer

    use Decorator.Define, trace: 0, trace: 1

    def trace(body, context) do
      trace([], body, context)
    end

    def trace(attributes, body, context) do
      name = Keyword.get(attributes, :name, default_name(context))
      tracer = Keyword.get(attributes, :tracer, @tracer)
      attributes = Keyword.delete(attributes, :tracer)

      quote do
        require unquote(tracer)

        unquote(tracer).trace unquote(name), unquote(attributes) do
          unquote(body)
        end
      end
    end

    defp default_name(%{module: module, name: function, arity: arity}) do
      module =
        module
        |> Atom.to_string()
        |> String.trim_leading("Elixir.")

      "#{module}.#{function}/#{arity}"
    end
  end
end
