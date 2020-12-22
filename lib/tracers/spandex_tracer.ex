defmodule ITKCommon.SpandexTracer do
  use Spandex.Tracer, otp_app: :itk_email

  defmacro __using__(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise("Tracer expects :otp_app to be given")
      Spandex.Tracer.__using__(opts)

      defp get_config() do
        config([], @otp_app)
      end
    end
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
