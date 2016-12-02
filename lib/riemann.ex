defmodule Riemann do
  use Application
  alias Riemann.Proto.Msg
  alias Riemann.Proto.Event
  alias Riemann.Proto.Query

  @moduledoc """
    A client for the Riemann event stream processor. http://riemann.io
  """

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    address = Application.get_env(:riemann, :address)
    args = [
      host: address[:host] || "127.0.0.1",
      port: address[:port] || 5555
    ]

    children = [
      Honeydew.queue_spec(:riemann_pool, failure_mode: Honeydew.FailureMode.Abandon),
      Honeydew.worker_spec(:riemann_pool, Riemann.Worker, args: args)
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
  def send(events, timeout \\ 5000) do
    events
    |> create_events_msg
    |> Msg.send(timeout)
  end

  @doc """
    see `send/1`
  """
  @spec send_async(nonempty_list) :: :ok | {:error, atom}
  def send_async(events) do
    events
    |> create_events_msg
    |> Msg.send_async
  end

  @doc false
  # queries are often going to include double quotes, so we'll support using char lists (single quotes)
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
    |> Msg.send
    |> case do
         :ok -> {:ok, []}
         {:ok, msg} -> {:ok, Event.deconstruct(msg.events)}
         {:error, msg} -> {:error, msg.error}
       end
  end


  defp create_events_msg(events) do
    [events: Event.list_to_events(events)]
    |> Msg.new
  end
end
