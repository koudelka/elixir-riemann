defmodule Riemann.Worker do
  use GenServer
  require Logger
  alias Riemann.Proto.Msg

  defmodule State do
    defstruct tcp: nil, host: nil, port: nil, from: nil
  end

  @ok_msg Msg.new(ok: true) |> Msg.encode
  def ok_msg, do: @ok_msg

  @error_msg Msg.new(ok: false) |> Msg.encode
  def error_msg, do: @error_msg


  @pool_name :worker_pool
  def pool_name, do: @pool_name

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, [])
  end

  def init([host: host, port: port]) do
    :timer.apply_after(0, GenServer, :call, [self, :connect])
    {:ok, %State{host: host, port: port}}
  end


  def handle_call(:connect, _from, state) do
    {reply, tcp} = case connect(state) do
      {:ok, tcp} -> {:ok, tcp}
      {:error, error} -> {{:error, error}, nil}
    end
    {:reply, reply, %{state | tcp: tcp}}
  end

  def handle_call({:send_msg, msg}, from, state) do
    case connect(state) do
      {:ok, tcp} ->
        :ok = :gen_tcp.send(tcp, Msg.encode(msg))
        # we'll reply once we get an ok from the server
        {:noreply, %{state | tcp: tcp, from: from}}
      error ->
        {:reply, error, %{state | tcp: nil}}
    end
  end

  # used for testing
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :unknown_msg, state}
  end


  # used for testing
  def handle_cast(:disconnect, %State{tcp: tcp} = state) do
    disconnect(tcp)
    {:noreply, %{state | tcp: nil}}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

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

  # the result of an async event send
  def handle_info({:tcp, _port, @ok_msg}, state) do
    {:noreply, state}
  end

  # unexpected message
  def handle_info({:tcp, _port, msg}, state) do
    Logger.info("Unexpected message from Riemann server: #{inspect msg}")
    {:noreply, state}
  end

  # connection dropped while waiting for a reply
  def handle_info({:tcp_closed, port}, %State{from: from} = state) when is_tuple(from) do
    GenServer.reply(from, {:error, :tcp_closed})
    handle_info({:tcp_closed, port}, %{state | from: nil})
  end

  # connection dropped, but we weren't waiting for a reply
  def handle_info({:tcp_closed, _port}, state) do
    {:noreply, %{state | tcp: nil}}
  end


  def terminate(_reason, %State{tcp: tcp}) when is_port(tcp) do
    disconnect(tcp)
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  defp connect(%State{tcp: tcp}) when is_port(tcp) do
    {:ok, tcp}
  end

  defp connect(%State{host: host, port: port}) do
    case connect(host, port) do
      {:error, error} ->
        Logger.error "Couldn't connect to Riemann server #{host}:#{port}, got #{inspect error}"
        {:error, error}
      ok -> ok
    end
  end

  defp connect(host, port) do
    # riemann message lengths are four bytes up front
    :gen_tcp.connect(:erlang.binary_to_list(host), port, [:binary, nodelay: true, packet: 4, active: true])
  end

  defp disconnect(tcp) do
    :gen_tcp.close(tcp)
  end
end
