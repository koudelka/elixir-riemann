defmodule Riemann.Helpers.Msg do
  defmacro __using__(_opts) do
    quote do

      def send(msg, :sync) do
        Riemann.Worker.call(:pool, {:send_msg, [msg]})
      end

      def send(msg, :async) do
        Riemann.Worker.cast(:pool, {:send_msg, [msg]})
      end

    end
  end
end
