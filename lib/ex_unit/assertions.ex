defexception ExUnit::AssertionError, message: "assertion failed"

defmodule ExUnit::Assertions do
  def assert_included(base, container) do
    if Erlang.string.str(container, base) == 0 do
      raise ExUnit::AssertionError, message: "Expected #{inspect container} to include #{inspect base}"
    end
  end
end