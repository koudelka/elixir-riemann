defmodule Riemann.Proto.MsgTest do
  use ExUnit.Case
  alias Riemann.Proto.Msg

  test "encode/1 sanity check" do
    msg = Msg.new(ok: true)
    assert Msg.encode(msg) == << 16, 1 >>
  end

end
