defmodule Riemann.Helpers.Msg do
  defmacro __using__(_opts) do
    quote do
      def send(msg, timeout \\ 5000) do
        {:send_msg, [msg]}
        |> Honeydew.async(:riemann_pool, reply: true)
        |> Honeydew.yield(timeout)
        |> case do
             {:ok, ok} -> ok
             nil -> :timeout
           end
      end

      def send_async(msg) do
        Honeydew.async({:send_msg, [msg]}, :riemann_pool)
      end
    end
  end
end
