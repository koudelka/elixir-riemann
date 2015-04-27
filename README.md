Riemann
=======

Riemann is (surprise!) a [Riemann](http://riemann.io) client for [Elixir](http://elixir-lang.org).

## Getting Started

Chuck this into your project config:

```elixir
defp deps do
  [{:riemann, " ~> 0.0.1"},
  {:exprotobuf, github: "koudelka/exprotobuf", branch: "injection-fix"},
  {:gpb, github: "tomas-abrahamsson/gpb", tag: "3.17.2", override: true}]
end
```

You'll also need to start the `:riemann` application, either manually (`Application.start(:riemann)`) or in your `mix.exs` application config.

## Usage
Riemann's interface is dead simple, you get `Riemann.send/1` and `Riemann.send_async/1`, blocking and non-blocking (just `call` and `cast`).

## Example
```elixir
Riemann.send(service: "my awesome app", metric: 5.0, attributes: [build: "7543"])

Riemann.send([
  [service: "my awesome app req", metric: 1, attributes: [build: "7543"]],
  [service: "things in queue", metric: 100, attributes: [build: "7543"]]
])

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
  - I haven't implemented querying yet.
  
   If you want UDP or querying, feel free to submit a PR (with tests 👺) or bug me to implement them.   

## License

See the LICENSE file. (spoiler: it's MIT)