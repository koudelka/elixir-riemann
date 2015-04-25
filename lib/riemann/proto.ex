defmodule Riemann.Proto do
  # this is broken, "from" isn't executed in the context of this module. :(
  # @proto_file Path.expand("riemann.proto", __DIR__)
  # @external_resource @proto_file
  # use Protobuf, from: @proto_file

  alias Riemann.Helpers
  use Protobuf, from: Path.expand("riemann.proto", __DIR__)
  use_in "Event", Helpers.Event
  use_in "Msg",   Helpers.Msg
  use_in "Attribute", Helpers.Attribute
end
