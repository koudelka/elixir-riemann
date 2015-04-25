defmodule Riemann do
  use Application
  alias Riemann.Worker
  alias Riemann.Proto.Msg
  alias Riemann.Proto.Event

  @moduledoc """
    A client for the Riemann event stream processor. http://riemann.io
  """

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    pool_options = [
      name: {:local, Worker.pool_name},
      worker_module: Riemann.Worker,
      size: 6,
      max_overflow: 10
    ]

    address = Application.get_env(:riemann, :address)
    worker_options = [
      host: address[:host],
      port: address[:port]
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
  @spec send(nonempty_list) :: :ok
  def send(events) do
    do_send(events, :sync)
  end

  @doc """
    see `send/1`
  """
  @spec send(nonempty_list) :: :ok | {:error, atom}
  def send_async(events) do
    do_send(events, :async)
  end

  @spec send(nonempty_list) :: :ok | {:error, atom}
  defp do_send(events, sync) do
    [events: Event.list_to_events(events)]
    |> Msg.new
    |> Msg.send(sync)
  end
end
