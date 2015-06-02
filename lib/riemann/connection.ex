defmodule Riemann.Connection do
  use GenServer
  require Logger
  alias Riemann.Proto.Msg

  defmodule State do
    defstruct tcp: nil, from: nil
  end

  @ok_msg Msg.new(ok: true) |> Msg.encode
  def ok_msg, do: @ok_msg

  @error_msg Msg.new(ok: false) |> Msg.encode
  def error_msg, do: @error_msg

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  # used for testing
  def start(state) do
    GenServer.start(__MODULE__, state, [])
  end

  def init([host: host, port: port]) do
    # riemann message lengths are four bytes up front
    {:ok, tcp} = :gen_tcp.connect(:erlang.binary_to_list(host), port, [:binary, nodelay: true, packet: 4, active: true])
    {:ok, %State{tcp: tcp}}
  end

  def handle_call({:send_msg, msg}, from, state) do
    :ok = :gen_tcp.send(state.tcp, Msg.encode(msg))
    # we'll reply once we get an ok from the server
    {:noreply, %{state | from: from}}
  end
  def handle_call(_msg, _from, state), do: {:reply, :unknown_msg, state}

  # a query that errored
  def handle_info({:tcp, _port, << @error_msg, rest :: binary >> = msg}, %State{from: from} = state) when is_tuple(from)
                                                                                                      and bit_size(rest) > 0 do
    GenServer.reply(from, {:error, Msg.decode(msg)})
    {:noreply, %{state | from: nil}}
  end

  # a successful query with a list of events
  def handle_info({:tcp, _port, << @ok_msg, rest :: binary >> = msg}, %State{from: from} = state) when is_tuple(from)
                                                                                                   and bit_size(rest) > 0 do
    GenServer.reply(from, {:ok, Msg.decode(msg)})
    {:noreply, %{state | from: nil}}
  end

  # a successful event send, or empty query results
  def handle_info({:tcp, _port, @ok_msg}, %State{from: from} = state) when is_tuple(from) do
    GenServer.reply(from, :ok)
    {:noreply, %{state | from: nil}}
  end

  # unexpected message
  def handle_info({:tcp, _port, msg}, state) do
    Logger.warn("Unexpected message from Riemann server: #{inspect msg}")
    {:noreply, state}
  end

  # connection dropped
  def handle_info({:tcp_closed, _port}, state) do
    {:stop, :tcp_closed, %{state | tcp: nil}}
  end


  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
