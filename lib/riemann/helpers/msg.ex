defmodule Riemann.Helpers.Msg do
  defmacro __using__(_opts) do
    quote do

      def send(msg, :sync) do
        :poolboy.transaction(Riemann.Worker.pool_name, &GenServer.call(&1, {:send_msg, msg}), :infinity)
      end

      def send(msg, :async) do
        # since this is a "fire and forget" event send, we want to wait forever for an available worker
        :poolboy.transaction(Riemann.Worker.pool_name, &GenServer.call(&1, {:send_msg, msg}), :infinity)
      end

    end
  end
end
