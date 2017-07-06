defmodule Riemann.Proto do
  use Protobuf, from: Path.expand("riemann.proto", __DIR__)
  @external_resource Path.expand("riemann.proto", __DIR__)

  use_in "Event", Riemann.Helpers.Event
  use_in "Msg",   Riemann.Helpers.Msg
  use_in "Attribute", Riemann.Helpers.Attribute
end
