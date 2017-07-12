defmodule Riemann.InvalidMetricError do
  defexception [:message]

  def exception(opts) do
    metric = Keyword.fetch!(opts, :metric)

    msg = """
    Expected metric to be of type integer or float, but got:

    #{inspect metric}
    """
    %__MODULE__{message: msg}
  end
end
