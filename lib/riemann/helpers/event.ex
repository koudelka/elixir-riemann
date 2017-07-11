defmodule Riemann.Helpers.Event do
  alias Riemann.Proto.Attribute

  defmacro __using__(_opts) do
    quote do
      alias Riemann.Proto.Attribute

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
        # Note: unquote(__MODULE__) is the module that's defined in this file
        # and __MODULE__ is the module that's using this module.
        unquote(__MODULE__).build(dict, __MODULE__)
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

  @moduledoc false
  def build(args, mod) do
    args
    |> Enum.into(%{})
    |> Map.put_new(:time, :erlang.system_time(:seconds))
    |> Map.put_new_lazy(:host, &default_event_host/0)
    |> set_attributes_field
    |> set_metric_pb_fields
    |> Map.to_list
    |> mod.new()
  end

  defp default_event_host do
    event_host_setting() || machine_hostname()
  end

  defp set_attributes_field(map) do
    case Map.get(map, :attributes) do
      nil -> map
      a   -> Map.put(map, :attributes, Attribute.build(a))
    end
  end

  defp set_metric_pb_fields(map) do
    case Map.get(map, :metric) do
      i when is_integer(i) -> Map.put(map, :metric_sint64, i)
      f when is_float(f)   -> Map.put(map, :metric_d, f)
      nil -> raise ArgumentError, "no metric provided for #{inspect map}"
    end
  end

  defp event_host_setting do
    Application.get_env(:riemann, :event_host)
  end

  defp machine_hostname do
    {:ok, hostname} = :inet.gethostname
    :erlang.list_to_binary(hostname)
  end
end
