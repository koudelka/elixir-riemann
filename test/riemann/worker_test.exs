defmodule Riemann.WorkerTest do
  use ExUnit.Case, async: false
  alias Riemann.Worker
  alias Riemann.Proto.Msg

  setup do
    {:ok, server} = TestServer.start(Riemann.Worker.ok_msg, self)

    on_exit fn ->
      TestServer.stop(server)
    end

    {:ok, server: server}
  end

  test "ok_msg/0 returns an 'ok' server response" do
    assert Worker.ok_msg == << 16, 1 >>
  end

  test "Worker holds a port after connecting, and dumps it when disconnected" do
    {:ok, worker} = Worker.start_link(Application.get_env(:riemann, :address))
    state = GenServer.call(worker, :state)
    assert is_port(state.tcp)

    GenServer.cast(worker, :disconnect)

    state = GenServer.call(worker, :state)
    refute state.tcp
  end

  test "Worker dumps its port when the connection drops", context do
    {:ok, worker} = Worker.start_link(Application.get_env(:riemann, :address))
    state = GenServer.call(worker, :state)
    assert is_port(state.tcp)

    TestServer.stop(context[:server])

    :timer.sleep 10 # wait for the connection-dropped message to arrive
    state = GenServer.call(worker, :state)
    refute state.tcp
  end

  test "Worker sends messages encoded" do
    {:ok, worker} = Worker.start_link(Application.get_env(:riemann, :address))

    msg = Msg.new(ok: false)
    :ok = GenServer.call(worker, {:send_msg, msg})

    encoded_msg = Msg.encode(msg)
    assert_received ^encoded_msg
  end

end
