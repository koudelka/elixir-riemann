defmodule Riemann.Helpers.Msg do
  defmacro __using__(_opts) do
    quote do

      def send(msg, timeout \\ 5000) do
        Riemann.Worker.call(:pool, {:send_msg, [msg]}, timeout)
      end

      def send_async(msg) do
        Riemann.Worker.cast(:pool, {:send_msg, [msg]})
      end

    end
  end
end
