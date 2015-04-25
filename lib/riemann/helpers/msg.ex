defmodule Riemann.Helpers.Msg do
  defmacro __using__(_opts) do
    quote do

      def send(msg, :sync) do
        :poolboy.transaction(Riemann.Worker.pool_name, &GenServer.call(&1, {:send_msg, msg}))
      end

      def send(msg, :async) do
        :poolboy.transaction(Riemann.Worker.pool_name, &GenServer.cast(&1, {:send_msg, msg}))
      end

    end
  end
end
