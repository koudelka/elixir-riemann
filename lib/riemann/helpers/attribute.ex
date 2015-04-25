defmodule Riemann.Helpers.Attribute do
  defmacro __using__(_opts) do
    quote do
      def build(attributes) do
        Enum.map(attributes, fn {k, v} ->
          new(key: to_string(k), value: to_string(v))
        end)
      end
    end
  end
end
