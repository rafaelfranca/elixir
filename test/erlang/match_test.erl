-module(match_test).
-include_lib("eunit/include/eunit.hrl").

no_assignment_test() ->
  {nil, []} = elixir:eval("").

% Var/assignment test
arithmetic_test() ->
  ?assertError({badmatch, _}, elixir:eval("-1 = 1")).

assignment_test() ->
  {1, [{a, 1}]} = elixir:eval("a = 1").

not_single_assignment_test() ->
  {2, [{a, 2}]} = elixir:eval("a = 1\na = 2\na"),
  {1, [{a, 1}]} = elixir:eval("{a,a} = {1,1}\na"),
  {1, [{a, 1}]} = elixir:eval("{a,a} = :{}.(1, 1)\na"),
  {2, [{a, 2}]} = elixir:eval("a = 1\n{^a,a} = {1,2}\na"),
  ?assertError({badmatch, _}, elixir:eval("{a,a} = {1,2}")),
  ?assertError({badmatch, _}, elixir:eval("{1 = a,a} = {1,2}")),
  ?assertError({badmatch, _}, elixir:eval("{a = 1,a} = {1,2}")),
  ?assertError({badmatch, _}, elixir:eval("a = 0;{a,a} = {1,2}")),
  ?assertError({badmatch, _}, elixir:eval("a = 0;{1 = a,a} = {1,2}")),
  ?assertError({badmatch, _}, elixir:eval("a = 1\n^a = 2")).

duplicated_assignment_on_module_with_tuple_test() ->
  F = fun() ->
    elixir:eval("defmodule Foo do\ndef v({ a, _left }, { a, _right }), do: a\nend"),
    {1,_} = elixir:eval("Foo.v({ 1, :foo }, { 1, :bar })"),
    ?assertError(function_clause, elixir:eval("Foo.v({ 1, :foo }, { 2, :bar })"))
  end,
  test_helper:run_and_remove(F, ['::Foo']).

duplicated_assignment_on_module_with_list_test() ->
  F = fun() ->
    elixir:eval("defmodule Foo do\ndef v([ a, _left ], [ a, _right ]), do: a\nend"),
    {1,_} = elixir:eval("Foo.v([ 1, :foo ], [ 1, :bar ])"),
    ?assertError(function_clause, elixir:eval("Foo.v([ 1, :foo ], [ 2, :bar ])"))
  end,
  test_helper:run_and_remove(F, ['::Foo']).

multiline_assignment_test() ->
  {1, [{a, 1}]} = elixir:eval("a =\n1"),
  {1, [{a, 1}, {b, 1}]} = elixir:eval("a = 1\nb = 1").

multiple_assignment_test() ->
  {1, [{a, 1}, {b, 1}]} = elixir:eval("a = b = 1").

multiple_assignment_with_parens_test() ->
  {1, [{a, 1}, {b, 1}]} = elixir:eval("a = (b = 1)").

multiple_assignment_with_left_parens_test() ->
  {1, [{a, 1}, {b, 1}]} = elixir:eval("(a) = (b = 1)").

multiple_assignment_with_expression_test() ->
  {-4, [{a, -4}, {b, -4}]} = elixir:eval("a = (b = -(2 * 2))").

multiple_assignment_with_binding_expression_test() ->
  {3, [{a, 3}, {b, 1}]} = elixir:eval("a = (2 + b)", [{b, 1}]).

underscore_assignment_test() ->
  {1, []} = elixir:eval("_ = 1").

assignment_precedence_test() ->
  {_, [{x,{ '__BLOCK__', _, [1,2,3]}}]} = elixir:eval("x = quote do\n1\n2\n3\nend").

% Tuples match
simple_tuple_test() ->
  {{}, _} = elixir:eval("a = {}"),
  {{1,2,3}, _} = elixir:eval("a = {1, 2, 3}"),
  {{1,2,3}, _} = elixir:eval("a = {1, 1 + 1, 3}"),
  {{1,{2},3}, _} = elixir:eval("a = {1, {2}, 3}").

tuple_match_test() ->
  {_, _} = elixir:eval("{1,2,3} = {1, 2, 3}"),
  ?assertError({badmatch, _}, elixir:eval("{1, 3, 2} = {1, 2, 3}")).

% Lists match
simple_list_test() ->
  {[], _} = elixir:eval("a = []"),
  {[1,2,3], _} = elixir:eval("a = [1, 2, 3]"),
  {[1,2,3], _} = elixir:eval("a = [1, 1 + 1, 3]"),
  {[1,[2],3], _} = elixir:eval("a = [1, [2], 3]"),
  {[1,{2},3], _} = elixir:eval("a = [1, {2}, 3]").

list_match_test() ->
  {_, _} = elixir:eval("[1, 2, 3] = [1, 2, 3]"),
  ?assertError({badmatch, _}, elixir:eval("[1, 3, 2] = [1, 2, 3]")).

list_vars_test() ->
  {[3,1], [{x,3}]} = elixir:eval("x = 1\n[x = x + 2, x]").

head_and_tail_test() ->
  {_,[{h,1},{t,[2,3]}]} = elixir:eval("[h|t] = [1,2,3]"),
  {_,[{h,2},{t,[3]}]} = elixir:eval("[1,h|t] = [1,2,3]"),
  {_,[{t,[3]}]} = elixir:eval("[1,2|t] = [1,2,3]"),
  {_,[{h,1}]} = elixir:eval("[h|[2,3]] = [1,2,3]"),
  {_,[{t,[2,3]}]} = elixir:eval("[+1|t] = [1,2,3]"),
  ?assertError({badmatch, _}, elixir:eval("[2,h|t] = [1,2,3]")).

% Orddict match

orrdict_match_test() ->
  {[{a,1},{b,2}], _} = elixir:eval("a = [a: 1, b: 2]"),
  {[{a,3},{b,2}], _} = elixir:eval("a = [a: 1, b: 2, a: 3]").

% Function match

function_clause_test() ->
  F = fun() ->
    elixir:eval("defmodule Foo do\ndef a([{_k,_}=e|_]), do: e\nend"),
    {{foo,bar},_} = elixir:eval("Foo.a([{:foo,:bar}])")
  end,
  test_helper:run_and_remove(F, ['::Foo']).