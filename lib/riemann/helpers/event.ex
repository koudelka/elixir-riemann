defmodule Riemann.Helpers.Event do
  defmacro __using__(_opts) do
    quote do
      alias Riemann.Proto.Attribute

      @event_host Application.get_env(:riemann, :event_host)

      # is_list(hd(list)) detects when it's a list of events, since keyword events are also lists
      # [[service: "a", metric: 1], %{service: "b", metric: 2}]
      def list_to_events(list) when is_list(hd(list)) or is_map(hd(list)) do
        Enum.map(list, &build/1)
      end

      # [service: "a", metric: 1]
      def list_to_events(keyword) do
        [keyword] |> list_to_events
      end

      def build(dict) do
        # i'd move this to a module attribute, but we can't assume that the build host is the runtime host.
        # could also stick it in the process dictionary if it's an issue
        {:ok, hostname} = :inet.gethostname
        hostname = @event_host || :erlang.list_to_binary(hostname)

        dict = Enum.into(dict, %{})
        dict = Map.merge(%{host: hostname, time: :erlang.system_time(:seconds)}, dict)
        dict = case Map.get(dict, :attributes) do
                 nil -> dict
                 a   -> Map.put(dict, :attributes, Attribute.build(a))
               end

        case Map.get(dict, :metric) do
          i when is_integer(i) -> Map.put(dict, :metric_sint64, i)
          f when is_float(f)   -> Map.put(dict, :metric_d, f)
          nil -> raise ArgumentError, "no metric provided for dict #{inspect dict}"
        end
        |> Map.to_list
        |> new()
      end


      def deconstruct(events) when is_list(events) do
        Enum.map(events, &deconstruct/1)
      end

      def deconstruct(%{metric_sint64: int} = event) when is_integer(int),  do: deconstruct(event, int)
      def deconstruct(%{metric_d: double}   = event) when is_float(double), do: deconstruct(event, double)
      def deconstruct(%{metric_f: float}    = event) when is_float(float),  do: deconstruct(event, float)
      def deconstruct(event), do: deconstruct(event, nil)

      def deconstruct(event, metric) do
        attributes = Enum.reduce(event.attributes, %{}, &Map.put(&2, &1.key, &1.value))

        event
        |> Map.from_struct
        |> Map.put(:metric, metric)
        |> Map.delete(:metric_d)
        |> Map.delete(:metric_f)
        |> Map.delete(:metric_sint64)
        |> Map.put(:attributes, attributes)
      end

    end
  end
end
