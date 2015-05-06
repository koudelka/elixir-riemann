defmodule Riemann do
  use Application
  alias Riemann.Worker
  alias Riemann.Proto.Msg
  alias Riemann.Proto.Event
  alias Riemann.Proto.Query

  @moduledoc """
    A client for the Riemann event stream processor. http://riemann.io
  """

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    {:ok, hostname} = :inet.gethostname
    hostname = :erlang.list_to_binary(hostname)
    Application.put_env(:riemann, :hostname, hostname)

    pool_options = [
      name: {:local, Worker.pool_name},
      worker_module: Riemann.Worker,
      size: 6,
      max_overflow: 10
    ]

    address = Application.get_env(:riemann, :address)
    worker_options = [
      host: address[:host] || "127.0.0.1",
      port: address[:port] || 5555
    ]

    children = [
      :poolboy.child_spec(Worker.pool_name, pool_options, worker_options)
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  @doc """
    Sends one or more events synchronously.

    For example:
    ``
      Riemann.send(service: "my awesome app", metric: 5.0, attributes: [build: "7543"])

      Riemann.send([
        [service: "my awesome app req", metric: 1, attributes: [build: "7543"]],
        [service: "things in queue", metric: 100, attributes: [build: "7543"]]
      ])
    ``
  """
  @spec send(nonempty_list) :: :ok | {:error, atom}
  def send(events) do
    do_send(events, :sync)
  end

  @doc """
    see `send/1`
  """
  @spec send_async(nonempty_list) :: :ok | {:error, atom}
  def send_async(events) do
    do_send(events, :async)
  end

  @doc false
  # queries are often goes to include double quotes, so
  # we'll support using char lists (single quotes)
  # ex: 'service = "my service"'
  def query(query_str) when is_list(query_str) do
    query_str
    |> :erlang.list_to_binary
    |> query
  end

  @doc """
    Asks the server for a list of events matching the provided query.
  """
  # @spec query(binary) :: {:ok, list} | {:error, atom}
  def query(query_str) do
    [query: Query.new(string: query_str)]
    |> Msg.new
    |> Msg.send(:sync)
    |> case do
         :ok -> {:ok, []}
         {:ok, msg} -> {:ok, Event.deconstruct(msg.events)}
         {:error, msg} -> {:error, msg.error}
       end
  end


  defp do_send(events, sync) do
    [events: Event.list_to_events(events)]
    |> Msg.new
    |> Msg.send(sync)
  end
end
