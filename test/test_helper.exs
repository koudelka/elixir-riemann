# janky test server ;D
defmodule TestServer do
  use GenServer

  def start(response, send_to) do
    {:ok, server} = GenServer.start(__MODULE__, [response, send_to])
    :ok = GenServer.call(server, :listen)
    {:ok, server}
  end

  def stop(server) do
    Process.exit(server, :byebye)
  end

  def init([response, send_to]) do
    {:ok, [response, send_to]}
  end

  def handle_call(:listen, _from, [response, send_to]) do
    port = Application.get_env(:riemann, :address)[:port]
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: 4, active: true, reuseaddr: true])
    clients = Enum.map(1..10, fn _ ->
      {:ok, client} = TestServer.Server.start_link(socket, response, send_to)
      client
    end)
    {:reply, :ok, [socket, clients, response, send_to]}
  end

  def terminate(_reason, [socket, _, _, _]) do
    :gen_tcp.close(socket)
  end

  defmodule Server do
    use GenServer

    def start_link(socket, response, send_to) do
      {:ok, client} = GenServer.start_link(__MODULE__, [socket, response, send_to])
      GenServer.cast(client, :accept)
      {:ok, client}
    end

    def init([socket, response, send_to]) do
      {:ok, [socket, response, send_to]}
    end

    def handle_cast(:accept, [socket, response, send_to]) do
      {:ok, client} = :gen_tcp.accept(socket)
      {:noreply, [client, response, send_to]}
    end

    def handle_info({:tcp, _port, msg}, [client, response, send_to]) do
      send(send_to, msg)
      :ok = :gen_tcp.send(client, response)
      {:noreply, [client, response, send_to]}
    end

    def handle_info(_msg, state) do
      {:noreply, state}
    end

    def terminate(_reason, [client, _, _]) do
      :gen_tcp.close(client)
    end
  end
end

ExUnit.start()
