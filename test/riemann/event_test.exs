defmodule Riemann.Proto.EventTest do
  use ExUnit.Case, async: false
  alias Riemann.Proto.Event
  alias Riemann.Proto.Attribute
  alias Riemann.InvalidMetricError

  describe "build/1" do
    setup :ensure_event_host_is_reset

    test "defaults hostname to the current machine's hostname" do
      %{host: host} = Event.build(metric: 1)
      actual_hostname = :inet.gethostname |> Tuple.to_list |> List.last |> :erlang.list_to_binary
      assert host == actual_hostname
    end

    test "allows the host to be overriden via param" do
      %{host: host} = Event.build(metric: 1, host: "overridden")
      assert host == "overridden"
    end

    defmodule TestEvent do
      use Riemann.Helpers.Event

      def new(args), do: Event.new(args)
    end

    test "grabs the hostname from the :event_host setting" do
      Application.put_env(:riemann, :event_host, "default host")

      %{host: host} = TestEvent.build(metric: 1)
      assert host == "default host"
    end

    test "adds time" do
      %{time: time} = Event.build(metric: 1)

      assert is_integer(time)
      assert time > 1429752659
    end

    test "allows time to be set" do
      assert %{time: 1234} = Event.build(metric: 1, time: 1234)
    end

    test "properly builds Attributes" do
      %{attributes: attributes} = Event.build(metric: 1, attributes: %{a: 1, b: 2})

      assert attributes == [%Attribute{key: "a", value: "1"},
                            %Attribute{key: "b", value: "2"}]
    end

    test "when no attributes property is given" do
      assert %{attributes: []} = Event.build(metric: 1)
    end

    test "places metric value into the correct protocol field" do
      %{metric_sint64: int, metric_d: double} = Event.build(metric: 1234)
      assert int == 1234
      assert double == nil

      %{metric_sint64: int, metric_d: double} = Event.build(metric: 1234.1234)
      assert int == nil
      assert double == 1234.1234
    end

    test "raises an error with a nil metric" do
      assert_raise ArgumentError, ~r/no metric provided/i, fn ->
        Event.build(metric: nil)
      end
    end

    test "raises an error on invalid metric data types" do
      assert_raise InvalidMetricError, fn ->
        Event.build(metric: %{count: 1})
      end

      assert_raise InvalidMetricError, fn ->
        Event.build(metric: [1, 2, 3])
      end

      assert_raise InvalidMetricError, fn ->
        Event.build(metric: "hello")
      end
    end
  end

  describe "deconstruct/1" do
    test "properly handles the incoming metric value" do
      event = Riemann.Proto.Event.new(metric_sint64: 1, metric_d: 2.0, metric_f: 3.0)
      assert Event.deconstruct(event).metric == 1

      event = Riemann.Proto.Event.new(metric_d: 2.0, metric_f: 3.0)
      assert Event.deconstruct(event).metric == 2.0

      event = Riemann.Proto.Event.new(metric_f: 3.0)
      assert Event.deconstruct(event).metric == 3.0

      event = Riemann.Proto.Event.new
      assert Event.deconstruct(event).metric == nil
    end

    test "converts attributes list to a map" do
      event = Riemann.Proto.Event.build(attributes: [a: 1, b: 2], metric: 1.0)
      assert Event.deconstruct(event).attributes == %{"a" => "1", "b" => "2"}

      event = Riemann.Proto.Event.build(attributes: [], metric: 1.0)
      assert Event.deconstruct(event).attributes == %{}
    end
  end

  defp ensure_event_host_is_reset(_) do
    result = Application.fetch_env(:riemann, :event_host)

    on_exit fn ->
      case result do
        {:ok, orig_event_host} ->
          Application.put_env(:riemann, :event_host, orig_event_host)
        :error -> Application.delete_env(:riemann, :event_host)
      end
    end

    :ok
  end
end
