defmodule Riemann.Helpers.Event do
  defmacro __using__(_opts) do
    quote do
      alias Riemann.Proto.Attribute

      # is_list(hd(list)) detects when it's a list of events, since keyword events are also lists
      # [[service: "a", metric: 1], %{service: "b", metric: 2}]
      def list_to_events(list) when is_list(hd(list)) or is_map(hd(list)) do
        Enum.map(list, &build/1)
      end

      # [service: "a", metric: 1]
      def list_to_events(dict) do
        [dict] |> list_to_events
      end

      def build(dict) do
        hostname = Application.get_env(:riemann, :hostname)
        dict = Dict.merge([host: hostname, time: now], dict)

        dict = case Dict.get(dict, :attributes) do
          nil -> dict
          a   -> Dict.put(dict, :attributes, Attribute.build(a))
        end

        case Dict.get(dict, :metric) do
          i when is_integer(i) -> Dict.put(dict, :metric_sint64, i)
          f when is_float(f)   -> Dict.put(dict, :metric_d, f)
          nil -> raise ArgumentError, "no metric provided for dict #{inspect dict}"
        end
        |> new
      end


      def deconstruct(events) when is_list(events) do
        Enum.map(events, &deconstruct/1)
      end

      def deconstruct(%{metric_sint64: int} = event) when is_integer(int),  do: deconstruct(event, int)
      def deconstruct(%{metric_d: double}   = event) when is_float(double), do: deconstruct(event, double)
      def deconstruct(%{metric_f: float}    = event) when is_float(float),  do: deconstruct(event, float)
      def deconstruct(event), do: deconstruct(event, nil)

      def deconstruct(event, metric) do
        attributes = Enum.reduce(event.attributes, %{}, &Dict.put(&2, &1.key, &1.value))

        event
        |> Map.from_struct
        |> Dict.put(:metric, metric)
        |> Dict.delete(:metric_d)
        |> Dict.delete(:metric_f)
        |> Dict.delete(:metric_sint64)
        |> Dict.put(:attributes, attributes)
      end

      defp now do
        {mega_secs, secs, _} = :erlang.now
        (mega_secs * 1_000_000) + secs
      end

    end
  end
end
