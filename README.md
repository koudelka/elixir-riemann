Riemann
=======

Riemann is (surprise!) a [Riemann](http://riemann.io) client for [Elixir](http://elixir-lang.org).

## Getting Started

Chuck this into your project config:

```elixir
defp deps do
  [{:riemann, " ~> 0.0.10"},
end
```

You'll also need to start the `:riemann` application, either manually (`Application.start(:riemann)`) or in your `mix.exs` application config.

## Usage

### Sending Events

Events are anything that implements the `Dict` protocol, so you'll likely want a `Keyword` list or a `Map`. 

If you want to send [custom attributes](http://riemann.io/howto.html#custom-event-attributes), stick them in the `attributes` key as a `Dict`. You can add in the `state` key, if you want to add a state to your event.

Send your events with `Riemann.send/1` and `Riemann.send_async/1`, blocking and non-blocking (just `call` and `cast`). They both expect an event, or a list of events.

```elixir
Riemann.send(service: "my awesome app", metric: 5.0, attributes: [build: "7543"])

Riemann.send_async([
  [service: "my awesome app req", metric: 1, state: "up", attributes: [build: "7543"]],
  %{service: "things in queue", metric: 100, attributes: [build: "7543"]}
])

```

### Querying for Events
To ask the server for a list of events [matching a query string](https://github.com/aphyr/riemann/blob/master/test/riemann/query_test.clj), use `Riemann.query/1`.

```elixir
{:ok, events} = Riemann.query('service ~= "my awesome"')                                               
#=> events = [%{attributes: %{"build" => "7543"}, description: nil, host: "dax",
#               metric: nil, service: "my awesome app", state: nil, tags: [],
#               time: 1430329965, ttl: 60.0},
#             %{attributes: %{"build" => "7543"}, description: nil, host: "dax", metric: 1,
#               service: "my awesome app req", state: "up", tags: [], time: 1430329965,
#               ttl: 60.0}]
```

## Configuration
Just toss this snippet into your environment's config:

```elixir
config :riemann, :address,
    host: "127.0.0.1",
    port: 5555
```

## Caveats
  - Only TCP is supported, read [this](http://riemann.io/howto.html#what-protocol-should-i-use-to-talk-to-riemann).
  
   If you want UDP, feel free to submit a PR (with tests 👺) or bug me to implement it.   

## License

See the LICENSE file. (spoiler: it's MIT)
