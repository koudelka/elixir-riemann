defmodule Riemann.Worker do
  use Honeydew
  alias Riemann.Connection

  def init(args) do
    Connection.start_link(args)
  end

  def send_msg(msg, connection) do
    GenServer.call(connection, {:send_msg, msg})
  end
end
