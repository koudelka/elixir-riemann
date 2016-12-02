defmodule Riemann.Helpers.Msg do
  defmacro __using__(_opts) do
    quote do
      alias Riemann.Worker

      def send(msg, timeout \\ 5000) do
        case Worker.async({:send_msg, [msg]}, :riemann_pool) |> Worker.yield(timeout) do
          {:ok, ok} -> ok
          nil -> :timeout
        end
      end

      def send_async(msg) do
        Worker.async({:send_msg, [msg]}, :riemann_pool, reply: false)
      end

    end
  end
end
