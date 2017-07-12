defmodule RiemannSendTest do
  use ExUnit.Case, async: false
  alias Riemann.Proto.Msg
  alias Riemann.Proto.Event
  alias Riemann.InvalidMetricError

  setup_all do
    Application.start(:gpb)
    Application.start(:exprotobuf)
    Application.start(:gen_stage)
    Application.start(:honeydew)

    :ok
  end

  setup do
    {:ok, server} = TestServer.start(Riemann.Connection.ok_msg, self())
    :ok = Application.start(:riemann)

    on_exit fn ->
      Application.stop(:riemann)
      TestServer.stop(server)
    end

    :ok
  end

  test "send/2 and send_async/1 send a single event" do
    event = [
      service: "riemann-elixir",
      metric: 1,
      attributes: [a: 1],
      description: "hurr durr"
    ]

    Riemann.send(event)
    assert_events_received(event)

    Riemann.send_async(event)
    assert_events_received(event)
  end

  test "send/2 and send_async/1 send many events" do
    events = [
      [
        service: "riemann-elixir",
        metric: 1,
        attributes: [a: 1],
        description: "hurr durr"
      ],
      [
        service: "riemann-elixir-2",
        metric: 1.123,
        attributes: [a: 1, "b": 2],
        description: "hurr durr dee durr"
      ],
      [
        service: "riemann-elixir-3",
        metric: 5.123,
        description: "hurr durr dee durr derp"
      ],
      [
        service: "riemann-elixir-4",
        state: "ok"
      ]
    ]

    Riemann.send(events)
    assert_events_received(events)

    Riemann.send_async(events)
    assert_events_received(events)
  end

  test "send/2 and send_async/1 with invalid metrics" do
    assert_raise InvalidMetricError, fn ->
      Riemann.send(metric: "hello")
    end

    assert_raise InvalidMetricError, fn ->
      Riemann.send(metric: %{count: 1})
    end

    assert_raise InvalidMetricError, fn ->
      Riemann.send(metric: [1, 2, 3])
    end

    assert_raise InvalidMetricError, fn ->
      Riemann.send_async(metric: "hello")
    end

    assert_raise InvalidMetricError, fn ->
      Riemann.send_async(metric: %{count: 1})
    end

    assert_raise InvalidMetricError, fn ->
      Riemann.send_async(metric: [1, 2, 3])
    end
  end

  test "send/2 should accept a timeout" do
    events = [
      [
        service: "riemann-elixir",
        metric: 1,
        attributes: [a: 1],
        description: "hurr durr"
      ]
    ]

    assert :timeout = Riemann.send(events, 0)
  end

  defp assert_events_received(events) do
    # TestServer sends us a message with what Riemann.send/2 sent it
    receive do
      msg -> assert Event.list_to_events(events) == Msg.decode(msg).events
    after 100 -> flunk()
    end
  end
end
