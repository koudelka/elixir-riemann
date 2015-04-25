defmodule Riemann.Proto.EventTest do
  use ExUnit.Case
  alias Riemann.Proto.Event
  alias Riemann.Proto.Attribute

  test "build/1 adds hostname and time" do
    %{host: host, time: time} = Event.build(metric: 1)

    actual_hostname = :inet.gethostname |> Tuple.to_list |> List.last |> :erlang.list_to_binary

    assert actual_hostname == host
    assert is_integer(time)
    assert time > 1429752659
  end

  test "build/1 properly builds Attributes" do
    %{attributes: attributes} = Event.build(metric: 1, attributes: %{a: 1, b: 2})

    assert attributes == [%Attribute{key: "a", value: "1"},
                          %Attribute{key: "b", value: "2"}]
  end

  test "build/1 places metric value into the correct protocol field" do
    %{metric_sint64: int, metric_d: double} = Event.build(metric: 1234)
    assert int == 1234
    assert double == nil

    %{metric_sint64: int, metric_d: double} = Event.build(metric: 1234.1234)
    assert int == nil
    assert double == 1234.1234
  end

end
