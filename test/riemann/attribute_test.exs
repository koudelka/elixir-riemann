defmodule Riemann.Proto.AttributeTest do
  use ExUnit.Case
  alias Riemann.Proto.Attribute

  test "build/1 creates structs with string keys/values" do
    assert Attribute.build(%{a: 1, "b": 2}) == [%Attribute{key: "a", value: "1"},
                                                %Attribute{key: "b", value: "2"}]
  end

end
