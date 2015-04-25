defmodule Riemann.Helpers.Event do
  defmacro __using__(_opts) do
    quote do
      alias Riemann.Proto.Attribute

      {:ok, hostname} = :inet.gethostname
      @hostname :erlang.list_to_binary(hostname)

      # is_list(hd()) detects when it's a list of events, since keyword events are also lists
      # [[service: "a", metric: 1], [service: "b", metric: 2]]
      def list_to_events(events) when is_list(hd(events)) do
        Enum.map(events, &build/1)
      end

      # [service: "a", metric: 1]
      def list_to_events(event) do
        [event] |> list_to_events
      end

      def build(event) do
        event = Dict.merge([host: @hostname, time: now], event)

        event = case Dict.get(event, :attributes) do
          nil -> event
          a   -> Dict.put(event, :attributes, Attribute.build(a))
        end

        case Dict.get(event, :metric) do
          i when is_integer(i) -> Dict.put(event, :metric_sint64, i)
          f when is_float(f)   -> Dict.put(event, :metric_d, f)
          nil -> raise ArgumentError, "no metric provided for event #{inspect event}"
        end
        |> new
      end

      defp now do
        {mega_secs, secs, _} = :erlang.now
        (mega_secs * 1_000_000) + secs
      end

    end
  end
end
