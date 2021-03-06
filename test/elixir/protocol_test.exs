Code.require_file "../test_helper", __FILE__

defprotocol ProtocolTest::WithAll, [blank(thing)]
defprotocol ProtocolTest::WithExcept, [blank(thing)], except: [Atom, Number, List]
defprotocol ProtocolTest::WithOnly, [blank(thing)], only: [Tuple, Function]

defrecord ProtocolTest::Foo, a: 0, b: 0

defimpl WithAll, for: Foo do
  def blank(record) do
    record.a + record.b == 0
  end
end

defmodule ProtocolTest do
  use ExUnit::Case

  def test_protocol_with_all do
    assert_undef(ProtocolTest::WithAll, Atom, :foo)
    assert_undef(ProtocolTest::WithAll, Function, fn(x, do: x))
    assert_undef(ProtocolTest::WithAll, Number, 1)
    assert_undef(ProtocolTest::WithAll, Number, 1.1)
    assert_undef(ProtocolTest::WithAll, List, [])
    assert_undef(ProtocolTest::WithAll, List, [1,2,3])
    assert_undef(ProtocolTest::WithAll, Tuple, {})
    assert_undef(ProtocolTest::WithAll, Tuple, {1,2,3})
    assert_undef(ProtocolTest::WithAll, Tuple, {Bar,2,3})
    assert_undef(ProtocolTest::WithAll, BitString, "foo")
    assert_undef(ProtocolTest::WithAll, BitString, <<1>>)
    assert_undef(ProtocolTest::WithAll, PID, self())
    assert_undef(ProtocolTest::WithAll, Port, hd(:erlang.ports))
    assert_undef(ProtocolTest::WithAll, Reference, make_ref)
  end

  def test_protocol_with_except do
    assert_undef(ProtocolTest::WithExcept, Any, :foo)
    assert_undef(ProtocolTest::WithExcept, Any, 1)
    assert_undef(ProtocolTest::WithExcept, Any, [1,2,3])
    assert_undef(ProtocolTest::WithExcept, Function, fn(x, do: x))
    assert_undef(ProtocolTest::WithExcept, Tuple, {})
  end

  def test_protocol_with_only do
    assert_undef(ProtocolTest::WithOnly, Any, :foo)
    assert_undef(ProtocolTest::WithOnly, Any, 1)
    assert_undef(ProtocolTest::WithOnly, Any, [1,2,3])
    assert_undef(ProtocolTest::WithOnly, Function, fn(x, do: x))
    assert_undef(ProtocolTest::WithOnly, Tuple, {})
  end

  def test_protocol_with_record do
    true  = ProtocolTest::WithAll.blank(ProtocolTest::Foo.new)
    false = ProtocolTest::WithAll.blank(ProtocolTest::Foo.new(a: 1))
  end

  def test_protocol_for do
    assert_protocol_for(ProtocolTest::WithAll, Atom, :foo)
    assert_protocol_for(ProtocolTest::WithAll, Function, fn(x, do: x))
    assert_protocol_for(ProtocolTest::WithAll, Number, 1)
    assert_protocol_for(ProtocolTest::WithAll, Number, 1.1)
    assert_protocol_for(ProtocolTest::WithAll, List, [])
    assert_protocol_for(ProtocolTest::WithAll, List, [1,2,3])
    assert_protocol_for(ProtocolTest::WithAll, Tuple, {})
    assert_protocol_for(ProtocolTest::WithAll, Tuple, {1,2,3})
    assert_protocol_for(ProtocolTest::WithAll, Record, {Bar,2,3})
    assert_protocol_for(ProtocolTest::WithAll, BitString, "foo")
    assert_protocol_for(ProtocolTest::WithAll, BitString, <<1>>)
    assert_protocol_for(ProtocolTest::WithAll, PID, self())
    assert_protocol_for(ProtocolTest::WithAll, Port, hd(:erlang.ports))
    assert_protocol_for(ProtocolTest::WithAll, Reference, make_ref)
  end

  # Assert that the given protocol is going to be dispatched.
  defp assert_protocol_for(target, impl, thing) do
    joined  = target::impl
    ^joined = target.__protocol_for__ thing
  end

  # Dispatch `blank(thing)` to the given `target`
  # and check if it will dispatch (and successfully fail)
  # to the proper implementation `impl`.
  defp assert_undef(target, impl, thing) do
    try do
      target.blank(thing)
      error("Expected invocation to fail")
    catch: :error, :undef, [stack|_]
      ref = target :: impl
      case hd(stack) do
      match: { ^ref, :blank, [^thing] }
        :ok
      match: { ^ref, :blank, [^thing], []}
        :ok
      else:
        error("Invalid stack #{stack}. Expected: { #{ref}, :blank, [#{thing}] }")
      end
    end
  end
end