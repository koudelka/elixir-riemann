defmodule RiemannQueryTest do
  use ExUnit.Case, async: false
  alias Riemann.Proto.Msg
  alias Riemann.Proto.Event

  setup_all do
    Application.start(:gpb)
    Application.start(:exprotobuf)
    Application.start(:honeydew)

    :ok
  end

  test "query/1 finds events" do
    constructed_events = [%Event{attributes: [%Riemann.Proto.Attribute{key: "build", value: "7543"}],
                                 description: nil, host: "dax", metric_d: 5.0,
                                 metric_f: 5.0, metric_sint64: nil, service: "my awesome app", state: nil,
                                 tags: [], time: 1430338512, ttl: 60.0},
                          %Event{attributes: [%Riemann.Proto.Attribute{key: "build", value: "7543"}],
                                 description: nil, host: "dax", metric_d: nil,
                                 metric_f: 1.0, metric_sint64: 1, service: "my awesome app req", state: "up",
                                 tags: [], time: 1430338513, ttl: 60.0}]

   msg = Msg.new(ok: true, events: constructed_events) |> Msg.encode

   {:ok, server} = TestServer.start(msg, self)
   Application.start(:riemann)

   query = "dummy query"
   {:ok, events} = Riemann.query(query)

   assert events == [%{attributes: %{"build" => "7543"}, description: nil, host: "dax", metric: 5.0,
                       service: "my awesome app", state: nil, tags: [], time: 1430338512,
                       ttl: 60.0},
                     %{attributes: %{"build" => "7543"}, description: nil, host: "dax", metric: 1,
                       service: "my awesome app req", state: "up", tags: [], time: 1430338513,
                       ttl: 60.0}]


   assert_query_received(query)

   Application.stop(:riemann)
   TestServer.stop(server)
  end

  test "query/1 finds no events" do
   msg = Msg.new(ok: false, error: "some error message") |> Msg.encode

   {:ok, server} = TestServer.start(msg, self)
   Application.start(:riemann)

   query = "dummy query"
   {:error, error} = Riemann.query(query)

   assert error == "some error message"

   assert_query_received(query)

   Application.stop(:riemann)
   TestServer.stop(server)
  end


  defp assert_query_received(query) do
    # TestServer sends us a message with what Riemann.query/1 sent it
    receive do
      msg -> assert query == Msg.decode(msg).query.string
    after 100 -> flunk
    end
  end
end
