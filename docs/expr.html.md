[![Previous](previous_motif.svg)](patterns.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](typedecl.html)

* * *

## ﻿11.7 Expressions

  * [11.7.1 Precedence and associativity](expr.html#ss%3Aprecedence-and-associativity)
  * [11.7.2 Basic expressions](expr.html#ss%3Aexpr-basic)
  * [11.7.3 Control structures](expr.html#ss%3Aexpr-control)
  * [11.7.4 Operations on data structures](expr.html#ss%3Aexpr-ops-on-data)
  * [11.7.5 Operators](expr.html#ss%3Aexpr-operators)
  * [11.7.6 Objects](expr.html#ss%3Aexpr-obj)
  * [11.7.7 Coercions](expr.html#ss%3Aexpr-coercions)
  * [11.7.8 Local structure items](expr.html#ss%3Aexpr-local-items)
  * [11.7.9 Other](expr.html#ss%3Aexpr-other)

| expr| ::=|  [value-path](names.html#value-path)  
---|---|---  
 | ∣|  [constant](const.html#constant)  
 | ∣|  ( expr )  
 | ∣|  begin expr end  
 | ∣|  ( expr : [typexpr](types.html#typexpr) )  
 | ∣|  expr { , expr }+  
 | ∣|  [constr](names.html#constr) expr  
 | ∣|  `[tag-name](names.html#tag-name) expr  
 | ∣|  expr :: expr  
 | ∣|  [ expr { ; expr } [;] ]  
 | ∣|  [| expr { ; expr } [;] |]  
 | ∣|  { [field](names.html#field) [: [typexpr](types.html#typexpr)] [= expr]{ ; [field](names.html#field) [: [typexpr](types.html#typexpr)] [= expr] } [;] }  
 | ∣|  { expr with [field](names.html#field) [: [typexpr](types.html#typexpr)] [= expr]{ ; [field](names.html#field) [: [typexpr](types.html#typexpr)] [= expr] } [;] }  
 | ∣|  expr { argument }+  
 | ∣|  [prefix-symbol](lex.html#prefix-symbol) expr  
 | ∣|  - expr  
 | ∣|  -. expr  
 | ∣|  expr [infix-op](names.html#infix-op) expr  
 | ∣|  expr . [field](names.html#field)  
 | ∣|  expr . [field](names.html#field) <- expr  
 | ∣|  expr .( expr )  
 | ∣|  expr .( expr ) <- expr  
 | ∣|  expr .[ expr ]  
 | ∣|  expr .[ expr ] <- expr  
 | ∣|  if expr then expr [ else expr ]   
 | ∣|  while expr do expr done  
 | ∣|  for [value-name](names.html#value-name) = expr ( to ∣ downto ) expr do expr done  
 | ∣|  expr ; expr  
 | ∣|  match expr with pattern-matching  
 | ∣|  function pattern-matching  
 | ∣|  fun { parameter }+ [ : [typexpr](types.html#typexpr) ] -> expr  
 | ∣|  try expr with pattern-matching  
 | ∣|  let [rec] let-binding { and let-binding } in expr  
 | ∣|  let [local-definition](modules.html#local-definition) in expr  
 | ∣|  ( expr :> [typexpr](types.html#typexpr) )  
 | ∣|  ( expr : [typexpr](types.html#typexpr) :> [typexpr](types.html#typexpr) )  
 | ∣|  assert expr  
 | ∣|  lazy expr  
 | ∣|  local-open-shorthand  
 | ∣|  object-expr  
  
  
| argument| ::=|  expr  
---|---|---  
 | ∣|  ~ [label-name](lex.html#label-name)  
 | ∣|  ~ [label-name](lex.html#label-name) : expr  
 | ∣|  ? [label-name](lex.html#label-name)  
 | ∣|  ? [label-name](lex.html#label-name) : expr  
  
pattern-matching| ::=|  [ | ] [pattern](patterns.html#pattern) [when expr] -> expr { | [pattern](patterns.html#pattern) [when expr] -> expr }   
  
let-binding| ::=|  [pattern](patterns.html#pattern) = expr  
 | ∣|  [value-name](names.html#value-name) { parameter } [: [typexpr](types.html#typexpr)] [:> [typexpr](types.html#typexpr)] = expr  
 | ∣|  [value-name](names.html#value-name) : [poly-typexpr](types.html#poly-typexpr) = expr  
  
parameter| ::=|  [pattern](patterns.html#pattern)  
 | ∣|  ~ [label-name](lex.html#label-name)  
 | ∣|  ~ ( [label-name](lex.html#label-name) [: [typexpr](types.html#typexpr)] )  
 | ∣|  ~ [label-name](lex.html#label-name) : [pattern](patterns.html#pattern)  
 | ∣|  ? [label-name](lex.html#label-name)  
 | ∣|  ? ( [label-name](lex.html#label-name) [: [typexpr](types.html#typexpr)] [= expr] )  
 | ∣|  ? [label-name](lex.html#label-name) : [pattern](patterns.html#pattern)  
 | ∣|  ? [label-name](lex.html#label-name) : ( [pattern](patterns.html#pattern) [: [typexpr](types.html#typexpr)] [= expr] )  
  
local-open-shorthand| ::=|  
 | ∣|  [module-path](names.html#module-path) .( expr )  
 | ∣|  [module-path](names.html#module-path) .[ expr ]  
 | ∣|  [module-path](names.html#module-path) .[| expr |]  
 | ∣|  [module-path](names.html#module-path) .{ expr }  
 | ∣|  [module-path](names.html#module-path) .{< expr >}  
  
object-expr| ::=|  
 | ∣|  new [class-path](names.html#class-path)  
 | ∣|  object [class-body](classes.html#class-body) end  
 | ∣|  expr # [method-name](names.html#method-name)  
 | ∣|  [inst-var-name](names.html#inst-var-name)  
 | ∣|  [inst-var-name](names.html#inst-var-name) <- expr  
 | ∣|  {< [ [inst-var-name](names.html#inst-var-name) [= expr] { ; [inst-var-name](names.html#inst-var-name) [= expr] } [;] ] >}  
  
See also the following language extensions: [first-class
modules](firstclassmodules.html#s%3Afirst-class-modules), [overriding in open
statements](overridingopen.html#s%3Aexplicit-overriding-open), [syntax for
Bigarray access](bigarray.html#s%3Abigarray-access),
[attributes](attributes.html#s%3Aattributes), [extension
nodes](extensionnodes.html#s%3Aextension-nodes), [extended indexing
operators](indexops.html#s%3Aindex-operators), [type-directed disambiguation
of array literals](arrayliterals.html#s%3Aarray-literals), and [labeled
tuples](labeledtuples.html#s%3Alabeled-tuples).

### ﻿11.7.1 Precedence and associativity

The table below shows the relative precedences and associativity of operators
and non-closed constructions. The constructions with higher precedence come
first. For infix and prefix symbols, we write “*…” to mean “any symbol
starting with *”.

Construction or operator| Associativity  
---|---  
prefix-symbol| –  
. .( .[ .{ (see section [12.11](bigarray.html#s%3Abigarray-access))| –  
#…| left  
function application, constructor application, tag application, assert, lazy|
left  
\- -. (prefix)| –  
**… lsl lsr asr| right  
*… /… %… mod land lor lxor| left   
+… -…| left  
::| right  
@… ^…| right  
=… <… >… |… &… $… !=| left  
& &&| right  
or ||| right  
,| –  
<\- :=| right  
if| –  
;| right  
let match fun function try| –  
  
It is simple to test or refresh one’s understanding:

# 3 + 3 mod 2, 3 + (3 mod 2), (3 + 3) mod 2;;

\- : int * int * int = (4, 4, 0)

### ﻿11.7.2 Basic expressions

#### ﻿Constants

An expression consisting in a constant evaluates to this constant. For
example, 3.14 or [||].

#### ﻿Value paths

An expression consisting in an access path evaluates to the value bound to
this path in the current evaluation environment. The path can be either a
value name or an access path to a value component of a module.

# Float.ArrayLabels.to_list;;

\- : Float.ArrayLabels.t -> float list = <fun>

#### ﻿Parenthesized expressions

The expressions ( expr ) and begin expr end have the same value as expr. The
two constructs are semantically equivalent, but it is good style to use begin
… end inside control structures:

    
    
            if … then begin … ; … end else begin … ; … end
    

and ( … ) for the other grouping situations.

# let x = 1 + 2 * 3 let y = (1 + 2) * 3;;

val x : int = 7 val y : int = 9

# let f a b = if a = b then print_endline "Equal" else begin print_string "Not
Equal: "; print_int a; print_string " and "; print_int b; print_newline ()
end;;

val f : int -> int -> unit = <fun>

Parenthesized expressions can contain a type constraint, as in ( expr :
[typexpr](types.html#typexpr) ). This constraint forces the type of expr to be
compatible with [typexpr](types.html#typexpr).

Parenthesized expressions can also contain coercions ( expr [:
[typexpr](types.html#typexpr)] :> [typexpr](types.html#typexpr)) (see
subsection 11.7.7 below).

#### ﻿Function application

Function application is denoted by juxtaposition of (possibly labeled)
expressions. The expression expr argument1 … argumentn evaluates the
expression expr and those appearing in argument1 to argumentn. The expression
expr must evaluate to a functional value f, which is then applied to the
values of argument1, …, argumentn.

The order in which the expressions expr, argument1, …, argumentn are evaluated
is not specified.

# List.fold_left ( + ) 0 [1; 2; 3; 4; 5];;

\- : int = 15

Arguments and parameters are matched according to their respective labels.
Argument order is irrelevant, except among arguments with the same label, or
no label.

# ListLabels.fold_left ~f:( @ ) ~init:[] [[1; 2; 3]; [4; 5; 6]; [7; 8; 9]];;

\- : int list = [1; 2; 3; 4; 5; 6; 7; 8; 9]

If a parameter is specified as optional (label prefixed by ?) in the type of
expr, the corresponding argument will be automatically wrapped with the
constructor Some, except if the argument itself is also prefixed by ?, in
which case it is passed as is.

# let fullname ?title first second = match title with | Some t -> t ^ " " ^ first ^ " " ^ second | None -> first ^ " " ^ second let name = fullname ~title:"Mrs" "Jane" "Fisher" let address ?title first second town = fullname ?title first second ^ "\n" ^ town;;

val fullname : ?title:string -> string -> string -> string = <fun> val name :
string = "Mrs Jane Fisher" val address : ?title:string -> string -> string ->
string -> string = <fun>

If a non-labeled argument is passed, and its corresponding parameter is
preceded by one or several optional parameters, then these parameters are
_defaulted_ , _i.e._ the value None will be passed for them. All other missing
parameters (without corresponding argument), both optional and non-optional,
will be kept, and the result of the function will still be a function of these
missing parameters to the body of f.

# let fullname ?title first second = match title with | Some t -> t ^ " " ^ first ^ " " ^ second | None -> first ^ " " ^ second let name = fullname "Jane" "Fisher";;

val fullname : ?title:string -> string -> string -> string = <fun> val name :
string = "Jane Fisher"

In all cases but exact match of order and labels, without optional parameters,
the function type should be known at the application point. This can be
ensured by adding a type constraint. Principality of the derivation can be
checked in the -principal mode.

As a special case, OCaml supports labels-omitted full applications: if the
function has a known arity, all the arguments are unlabeled, and their number
matches the number of non-optional parameters, then labels are ignored and
non-optional parameters are matched in their definition order. Optional
arguments are defaulted. This omission of labels is discouraged and results in
a warning, see [13.5.1](comp.html#ss%3Awarn6).

#### ﻿Function definition

Two syntactic forms are provided to define functions. The first form is
introduced by the keyword function:

| function| pattern1| ->| expr1  
---|---|---|---  
|| …  
|| patternn| ->| exprn  
  
This expression evaluates to a functional value with one argument. When this
function is applied to a value v, this value is matched against each pattern
[pattern](patterns.html#pattern)1 to [pattern](patterns.html#pattern)n. If one
of these matchings succeeds, that is, if the value v matches the pattern
[pattern](patterns.html#pattern)i for some i, then the expression expri
associated to the selected pattern is evaluated, and its value becomes the
value of the function application. The evaluation of expri takes place in an
environment enriched by the bindings performed during the matching.

If several patterns match the argument v, the one that occurs first in the
function definition is selected. If none of the patterns matches the argument,
the exception Match_failure is raised.

# (function (0, 0) -> "both zero" | (0, _) -> "first only zero" | (_, 0) -> "second only zero" | (_, _) -> "neither zero") (7, 0);;

\- : string = "second only zero"

The other form of function definition is introduced by the keyword fun:

fun parameter1 … parametern -> expr

This expression is equivalent to:

fun parameter1 -> … fun parametern -> expr

# let f = (fun a -> fun b -> fun c -> a + b + c) let g = (fun a b c -> a + b +
c);;

val f : int -> int -> int -> int = <fun> val g : int -> int -> int -> int =
<fun>

An optional type constraint [typexpr](types.html#typexpr) can be added before
-> to enforce the type of the result to be compatible with the constraint
[typexpr](types.html#typexpr):

fun parameter1 … parametern : [typexpr](types.html#typexpr) -> expr

is equivalent to

fun parameter1 -> … fun parametern -> (expr : [typexpr](types.html#typexpr) )

Beware of the small syntactic difference between a type constraint on the last
parameter

fun parameter1 … (parametern:[typexpr](types.html#typexpr))-> expr

and one on the result

fun parameter1 … parametern: [typexpr](types.html#typexpr) -> expr

# let eq = fun (a : int) (b : int) -> a = b let eq2 = fun a b : bool -> a = b
let eq3 = fun (a : int) (b : int) : bool -> a = b;;

val eq : int -> int -> bool = <fun> val eq2 : 'a -> 'a -> bool = <fun> val eq3
: int -> int -> bool = <fun>

The parameter patterns ~[lab](lex.html#label-name) and ~([lab](lex.html#label-
name) [: [typ](types.html#typexpr)]) are shorthands for respectively
~[lab](lex.html#label-name):[lab](lex.html#label-name) and
~[lab](lex.html#label-name):([lab](lex.html#label-name) [:
[typ](types.html#typexpr)]), and similarly for their optional counterparts.

# let bool_map ~cmp:(cmp : int -> int -> bool) l = List.map cmp l let
bool_map' ~(cmp : int -> int -> bool) l = List.map cmp l;;

val bool_map : cmp:(int -> int -> bool) -> int list -> (int -> bool) list =
<fun> val bool_map' : cmp:(int -> int -> bool) -> int list -> (int -> bool)
list = <fun>

A function of the form fun ? [lab](lex.html#label-name) :(
[pattern](patterns.html#pattern) = expr0 ) -> expr is equivalent to

fun ? [lab](lex.html#label-name) : [ident](lex.html#ident) -> let [pattern](patterns.html#pattern) = match [ident](lex.html#ident) with Some [ident](lex.html#ident) -> [ident](lex.html#ident) | None -> expr0 in expr

where [ident](lex.html#ident) is a fresh variable, except that it is
unspecified when expr0 is evaluated.

# let open_file_for_input ?binary filename = match binary with | Some true -> open_in_bin filename | Some false | None -> open_in filename let open_file_for_input' ?(binary=false) filename = if binary then open_in_bin filename else open_in filename;;

val open_file_for_input : ?binary:bool -> string -> in_channel = <fun> val
open_file_for_input' : ?binary:bool -> string -> in_channel = <fun>

After these two transformations, expressions are of the form

fun [[label](lex.html#label)1] [pattern](patterns.html#pattern)1 -> … fun
[[label](lex.html#label)n] [pattern](patterns.html#pattern)n -> expr

If we ignore labels, which will only be meaningful at function application,
this is equivalent to

function [pattern](patterns.html#pattern)1 -> … function
[pattern](patterns.html#pattern)n -> expr

That is, the fun expression above evaluates to a curried function with n
arguments: after applying this function n times to the values v1 … vn, the
values will be matched in parallel against the patterns
[pattern](patterns.html#pattern)1 … [pattern](patterns.html#pattern)n. If the
matching succeeds, the function returns the value of expr in an environment
enriched by the bindings performed during the matchings. If the matching
fails, the exception Match_failure is raised.

#### ﻿Guards in pattern-matchings

The cases of a pattern matching (in the function, match and try constructs)
can include guard expressions, which are arbitrary boolean expressions that
must evaluate to true for the match case to be selected. Guards occur just
before the -> token and are introduced by the when keyword:

| function| pattern1 [when cond1]| ->| expr1  
---|---|---|---  
|| …  
|| patternn [when condn]| ->| exprn  
  
Matching proceeds as described before, except that if the value matches some
pattern [pattern](patterns.html#pattern)i which has a guard condi, then the
expression condi is evaluated (in an environment enriched by the bindings
performed during matching). If condi evaluates to true, then expri is
evaluated and its value returned as the result of the matching, as usual. But
if condi evaluates to false, the matching is resumed against the patterns
following [pattern](patterns.html#pattern)i.

# let rec repeat f = function | 0 -> () | n when n > 0 -> f (); repeat f (n - 1) | _ -> raise (Invalid_argument "repeat");;

val repeat : (unit -> 'a) -> int -> unit = <fun>

#### ﻿Local definitions

The let and let rec constructs bind value names locally. The construct

let [pattern](patterns.html#pattern)1 = expr1 and … and
[pattern](patterns.html#pattern)n = exprn in expr

evaluates expr1 … exprn in some unspecified order and matches their values
against the patterns [pattern](patterns.html#pattern)1 …
[pattern](patterns.html#pattern)n. If the matchings succeed, expr is evaluated
in the environment enriched by the bindings performed during matching, and the
value of expr is returned as the value of the whole let expression. If one of
the matchings fails, the exception Match_failure is raised.

# let v = let x = 1 in [x; x; x] let v' = let a, b = (1, 2) in a + b let v'' =
let a = 1 and b = 2 in a + b;;

val v : int list = [1; 1; 1] val v' : int = 3 val v'' : int = 3

An alternate syntax is provided to bind variables to functional values:
instead of writing

let [ident](lex.html#ident) = fun parameter1 … parameterm -> expr

in a let expression, one may instead write

let [ident](lex.html#ident) parameter1 … parameterm = expr

# let f = fun x -> fun y -> fun z -> x + y + z let f' = fun x y z -> x + y + z
let f'' x y z = x + y + z;;

val f : int -> int -> int -> int = <fun> val f' : int -> int -> int -> int =
<fun> val f'' : int -> int -> int -> int = <fun>

Recursive definitions of names are introduced by let rec:

let rec [pattern](patterns.html#pattern)1 = expr1 and … and
[pattern](patterns.html#pattern)n = exprn in expr

The only difference with the let construct described above is that the
bindings of names to values performed by the pattern-matching are considered
already performed when the expressions expr1 to exprn are evaluated. That is,
the expressions expr1 to exprn can reference identifiers that are bound by one
of the patterns [pattern](patterns.html#pattern)1, …,
[pattern](patterns.html#pattern)n, and expect them to have the same value as
in expr, the body of the let rec construct.

# let rec even = function 0 -> true | n -> odd (n - 1) and odd = function 0 -> false | n -> even (n - 1) in even 1000;;

\- : bool = true

The recursive definition is guaranteed to behave as described above if the
expressions expr1 to exprn are function definitions (fun … or function …), and
the patterns [pattern](patterns.html#pattern)1 …
[pattern](patterns.html#pattern)n are just value names, as in:

let rec name1 = fun … and … and namen = fun … in expr

This defines name1 … namen as mutually recursive functions local to expr.

The behavior of other forms of let rec definitions is implementation-
dependent. The current implementation also supports a certain class of
recursive definitions of non-functional values, as explained in section
[12.1](letrecvalues.html#s%3Aletrecvalues).

#### ﻿Explicit polymorphic type annotations

(Introduced in OCaml 3.12)

Polymorphic type annotations in let-definitions behave in a way similar to
polymorphic methods:

let [pattern](patterns.html#pattern)1 : [typ](types.html#typexpr)1 …
[typ](types.html#typexpr)n . [typexpr](types.html#typexpr) = expr

These annotations explicitly require the defined value to be polymorphic, and
allow one to use this polymorphism in recursive occurrences (when using let
rec). Note however that this is a normal polymorphic type, unifiable with any
instance of itself.

### ﻿11.7.3 Control structures

#### ﻿Sequence

The expression expr1 ; expr2 evaluates expr1 first, then expr2, and returns
the value of expr2.

# let print_pair (a, b) = print_string "("; print_string (string_of_int a);
print_string ","; print_string (string_of_int b); print_endline ")";;

val print_pair : int * int -> unit = <fun>

#### ﻿Conditional

The expression if expr1 then expr2 else expr3 evaluates to the value of expr2
if expr1 evaluates to the boolean true, and to the value of expr3 if expr1
evaluates to the boolean false.

# let rec factorial x = if x <= 1 then 1 else x * factorial (x - 1);;

val factorial : int -> int = <fun>

The else expr3 part can be omitted, in which case it defaults to else ().

# let debug = ref false let log msg = if !debug then prerr_endline msg;;

val debug : bool ref = {contents = false} val log : string -> unit = <fun>

#### ﻿Case expression

The expression

| match| expr  
---|---  
with| pattern1| ->| expr1  
|| …  
|| patternn| ->| exprn  
  
matches the value of expr against the patterns
[pattern](patterns.html#pattern)1 to [pattern](patterns.html#pattern)n. If the
matching against [pattern](patterns.html#pattern)i succeeds, the associated
expression expri is evaluated, and its value becomes the value of the whole
match expression. The evaluation of expri takes place in an environment
enriched by the bindings performed during matching. If several patterns match
the value of expr, the one that occurs first in the match expression is
selected.

# let rec sum l = match l with | [] -> 0 | h :: t -> h + sum t;;

val sum : int list -> int = <fun>

If none of the patterns match the value of expr, the exception Match_failure
is raised.

# let unoption o = match o with | Some x -> x ;;

Warning 8 [partial-match]: this pattern-matching is not exhaustive. Here is an
example of a case that is not matched: None val unoption : 'a option -> 'a =
<fun>

# let l = List.map unoption [Some 1; Some 10; None; Some 2];;

Exception: Match_failure ("expr.etex", 2, 2).

#### ﻿Boolean operators

The expression expr1 && expr2 evaluates to true if both expr1 and expr2
evaluate to true; otherwise, it evaluates to false. The first component,
expr1, is evaluated first. The second component, expr2, is not evaluated if
the first component evaluates to false. Hence, the expression expr1 && expr2
behaves exactly as

if expr1 then expr2 else false.

The expression expr1 || expr2 evaluates to true if one of the expressions
expr1 and expr2 evaluates to true; otherwise, it evaluates to false. The first
component, expr1, is evaluated first. The second component, expr2, is not
evaluated if the first component evaluates to true. Hence, the expression
expr1 || expr2 behaves exactly as

if expr1 then true else expr2.

The boolean operators & and or are deprecated synonyms for (respectively) &&
and ||.

# let xor a b = (a || b) && not (a && b);;

val xor : bool -> bool -> bool = <fun>

#### ﻿Loops

The expression while expr1 do expr2 done repeatedly evaluates expr2 while
expr1 evaluates to true. The loop condition expr1 is evaluated and tested at
the beginning of each iteration. The whole while … done expression evaluates
to the unit value ().

# let chars_of_string s = let i = ref 0 in let chars = ref [] in while !i <
String.length s do chars := s.[!i] :: !chars; i := !i + 1 done; List.rev
!chars;;

val chars_of_string : string -> char list = <fun>

As a special case, while true do expr done is given a polymorphic type,
allowing it to be used in place of any expression (for example as a branch of
any pattern-matching).

The expression for name = expr1 to expr2 do expr3 done first evaluates the
expressions expr1 and expr2 (the boundaries) into integer values n and p.
Then, the loop body expr3 is repeatedly evaluated in an environment where name
is successively bound to the values n, n+1, …, p−1, p. The loop body is never
evaluated if n > p.

# let chars_of_string s = let l = ref [] in for p = 0 to String.length s - 1
do l := s.[p] :: !l done; List.rev !l;;

val chars_of_string : string -> char list = <fun>

The expression for name = expr1 downto expr2 do expr3 done evaluates
similarly, except that name is successively bound to the values n, n−1, …,
p+1, p. The loop body is never evaluated if n < p.

# let chars_of_string s = let l = ref [] in for p = String.length s - 1 downto
0 do l := s.[p] :: !l done; !l;;

val chars_of_string : string -> char list = <fun>

In both cases, the whole for expression evaluates to the unit value ().

#### ﻿Exception handling

The expression

| try | expr  
---|---  
with| pattern1| ->| expr1  
|| …  
|| patternn| ->| exprn  
  
evaluates the expression expr and returns its value if the evaluation of expr
does not raise any exception. If the evaluation of expr raises an exception,
the exception value is matched against the patterns
[pattern](patterns.html#pattern)1 to [pattern](patterns.html#pattern)n. If the
matching against [pattern](patterns.html#pattern)i succeeds, the associated
expression expri is evaluated, and its value becomes the value of the whole
try expression. The evaluation of expri takes place in an environment enriched
by the bindings performed during matching. If several patterns match the value
of expr, the one that occurs first in the try expression is selected. If none
of the patterns matches the value of expr, the exception value is raised
again, thereby transparently “passing through” the try construct.

# let find_opt p l = try Some (List.find p l) with Not_found -> None;;

val find_opt : ('a -> bool) -> 'a list -> 'a option = <fun>

### ﻿11.7.4 Operations on data structures

#### ﻿Products

The expression expr1 , … , exprn evaluates to the n-tuple of the values of
expressions expr1 to exprn. The evaluation order of the subexpressions is not
specified.

# (1 + 2 * 3, (1 + 2) * 3, 1 + (2 * 3));;

\- : int * int * int = (7, 9, 7)

#### ﻿Variants

The expression [constr](names.html#constr) expr evaluates to the unary variant
value whose constructor is [constr](names.html#constr), and whose argument is
the value of expr. Similarly, the expression [constr](names.html#constr) (
expr1 , … , exprn ) evaluates to the n-ary variant value whose constructor is
[constr](names.html#constr) and whose arguments are the values of expr1, …,
exprn.

The expression [constr](names.html#constr) (expr1, …, exprn) evaluates to the
variant value whose constructor is [constr](names.html#constr), and whose
arguments are the values of expr1 … exprn.

# type t = Var of string | Not of t | And of t * t | Or of t * t let test = And (Var "x", Not (Or (Var "y", Var "z")));;

type t = Var of string | Not of t | And of t * t | Or of t * t val test : t = And (Var "x", Not (Or (Var "y", Var "z")))

For lists, some syntactic sugar is provided. The expression expr1 :: expr2
stands for the constructor ( :: ) applied to the arguments ( expr1 , expr2 ),
and therefore evaluates to the list whose head is the value of expr1 and whose
tail is the value of expr2. The expression [ expr1 ; … ; exprn ] is equivalent
to expr1 :: … :: exprn :: [], and therefore evaluates to the list whose
elements are the values of expr1 to exprn.

# 0 :: [1; 2; 3] = 0 :: 1 :: 2 :: 3 :: [];;

\- : bool = true

#### ﻿Polymorphic variants

The expression `[tag-name](names.html#tag-name) expr evaluates to the
polymorphic variant value whose tag is [tag-name](names.html#tag-name), and
whose argument is the value of expr.

# let with_counter x = `V (x, ref 0);;

val with_counter : 'a -> [> `V of 'a * int ref ] = <fun>

#### ﻿Records

The expression { [field](names.html#field)1 [= expr1] ; … ;
[field](names.html#field)n [= exprn ]} evaluates to the record value { field1
= v1; …; fieldn = vn } where vi is the value of expri for i = 1,… , n. A
single identifier [field](names.html#field)k stands for
[field](names.html#field)k = [field](names.html#field)k, and a qualified
identifier [module-path](names.html#module-path) . [field](names.html#field)k
stands for [module-path](names.html#module-path) . [field](names.html#field)k
= [field](names.html#field)k. The fields [field](names.html#field)1 to
[field](names.html#field)n must all belong to the same record type; each field
of this record type must appear exactly once in the record expression, though
they can appear in any order. The order in which expr1 to exprn are evaluated
is not specified. Optional type constraints can be added after each field {
[field](names.html#field)1 : [typexpr](types.html#typexpr)1 = expr1 ;… ;
[field](names.html#field)n : [typexpr](types.html#typexpr)n = exprn } to force
the type of [field](names.html#field)k to be compatible with
[typexpr](types.html#typexpr)k.

# type t = {house_no : int; street : string; town : string; postcode : string}
let address x = Printf.sprintf "The occupier\n%i %s\n%s\n%s" x.house_no
x.street x.town x.postcode;;

type t = { house_no : int; street : string; town : string; postcode : string;
} val address : t -> string = <fun>

The expression { expr with [field](names.html#field)1 [= expr1] ; … ;
[field](names.html#field)n [= exprn] } builds a fresh record with fields
[field](names.html#field)1 … [field](names.html#field)n equal to expr1 …
exprn, and all other fields having the same value as in the record expr. In
other terms, it returns a shallow copy of the record expr, except for the
fields [field](names.html#field)1 … [field](names.html#field)n, which are
initialized to expr1 … exprn. As previously, single identifier
[field](names.html#field)k stands for [field](names.html#field)k =
[field](names.html#field)k, a qualified identifier [module-
path](names.html#module-path) . [field](names.html#field)k stands for [module-
path](names.html#module-path) . [field](names.html#field)k =
[field](names.html#field)k and it is possible to add an optional type
constraint on each field being updated with { expr with
[field](names.html#field)1 : [typexpr](types.html#typexpr)1 = expr1 ; … ;
[field](names.html#field)n : [typexpr](types.html#typexpr)n = exprn }.

# type t = {house_no : int; street : string; town : string; postcode : string}
let uppercase_town address = {address with town = String.uppercase_ascii
address.town};;

type t = { house_no : int; street : string; town : string; postcode : string;
} val uppercase_town : t -> t = <fun>

The expression expr1 . [field](names.html#field) evaluates expr1 to a record
value, and returns the value associated to [field](names.html#field) in this
record value.

The expression expr1 . [field](names.html#field) <- expr2 evaluates expr1 to a
record value, which is then modified in-place by replacing the value
associated to [field](names.html#field) in this record by the value of expr2.
This operation is permitted only if [field](names.html#field) has been
declared mutable in the definition of the record type. The whole expression
expr1 . [field](names.html#field) <- expr2 evaluates to the unit value ().

# type t = {mutable upper : int; mutable lower : int; mutable other : int} let stats = {upper = 0; lower = 0; other = 0} let collect = String.iter (function | 'A'..'Z' -> stats.upper <\- stats.upper + 1 | 'a'..'z' -> stats.lower <\- stats.lower + 1 | _ -> stats.other <\- stats.other + 1);;

type t = { mutable upper : int; mutable lower : int; mutable other : int; }
val stats : t = {upper = 0; lower = 0; other = 0} val collect : string -> unit
= <fun>

#### ﻿Arrays

The expression [| expr1 ; … ; exprn |] evaluates to a n-element array, whose
elements are initialized with the values of expr1 to exprn respectively. The
order in which these expressions are evaluated is unspecified.

The expression expr1 .( expr2 ) returns the value of element number expr2 in
the array denoted by expr1. The first element has number 0; the last element
has number n−1, where n is the size of the array. The exception
Invalid_argument is raised if the access is out of bounds.

The expression expr1 .( expr2 ) <- expr3 modifies in-place the array denoted
by expr1, replacing element number expr2 by the value of expr3. The exception
Invalid_argument is raised if the access is out of bounds. The value of the
whole expression is ().

# let scale arr n = for x = 0 to Array.length arr - 1 do arr.(x) <\- arr.(x) *
n done let x = [|1; 10; 100|] let _ = scale x 2;;

val scale : int array -> int -> unit = <fun> val x : int array = [|2; 20;
200|]

#### ﻿Strings

The expression expr1 .[ expr2 ] returns the value of character number expr2 in
the string denoted by expr1. The first character has number 0; the last
character has number n−1, where n is the length of the string. The exception
Invalid_argument is raised if the access is out of bounds.

# let iter f s = for x = 0 to String.length s - 1 do f s.[x] done;;

val iter : (char -> 'a) -> string -> unit = <fun>

The expression expr1 .[ expr2 ] <- expr3 modifies in-place the string denoted
by expr1, replacing character number expr2 by the value of expr3. The
exception Invalid_argument is raised if the access is out of bounds. The value
of the whole expression is (). Note: this possibility is offered only for
backward compatibility with older versions of OCaml and will be removed in a
future version. New code should use byte sequences and the Bytes.set function.

### ﻿11.7.5 Operators

Symbols from the class [infix-symbol](lex.html#infix-symbol), as well as the
keywords *, +, -, -., =, !=, <, >, or, ||, &, &&, :=, mod, land, lor, lxor,
lsl, lsr, and asr can appear in infix position (between two expressions).
Symbols from the class [prefix-symbol](lex.html#prefix-symbol), as well as the
keywords - and -. can appear in prefix position (in front of an expression).

# (( * ), ( := ), ( || ));;

\- : (int -> int -> int) * ('a ref -> 'a -> unit) * (bool -> bool -> bool) =
(<fun>, <fun>, <fun>)

Infix and prefix symbols do not have a fixed meaning: they are simply
interpreted as applications of functions bound to the names corresponding to
the symbols. The expression [prefix-symbol](lex.html#prefix-symbol) expr is
interpreted as the application ( [prefix-symbol](lex.html#prefix-symbol) )
expr. Similarly, the expression expr1 [infix-symbol](lex.html#infix-symbol)
expr2 is interpreted as the application ( [infix-symbol](lex.html#infix-
symbol) ) expr1 expr2.

The table below lists the symbols defined in the initial environment and their
initial meaning. (See the description of the core library module Stdlib in
chapter [29](core.html#c%3Acorelib) for more details). Their meaning may be
changed at any time using let ( [infix-op](names.html#infix-op) ) name1 name2
= …

# let ( + ), ( - ), ( * ), ( / ) = Int64.(add, sub, mul, div);;

val ( + ) : int64 -> int64 -> int64 = <fun> val ( - ) : int64 -> int64 ->
int64 = <fun> val ( * ) : int64 -> int64 -> int64 = <fun> val ( / ) : int64 ->
int64 -> int64 = <fun>

Note: the operators &&, ||, and ~- are handled specially and it is not
advisable to change their meaning.

The keywords - and -. can appear both as infix and prefix operators. When they
appear as prefix operators, they are interpreted respectively as the functions
(~-) and (~-.).

Operator| Initial meaning  
---|---  
+| Integer addition.  
- (infix)| Integer subtraction.   
~- - (prefix)| Integer negation.  
*| Integer multiplication.   
/| Integer division. Raise Division_by_zero if second argument is zero.  
mod| Integer modulus. Raise Division_by_zero if second argument is zero.  
land| Bitwise logical “and” on integers.  
lor| Bitwise logical “or” on integers.  
lxor| Bitwise logical “exclusive or” on integers.  
lsl| Bitwise logical shift left on integers.  
lsr| Bitwise logical shift right on integers.  
asr| Bitwise arithmetic shift right on integers.  
+.| Floating-point addition.  
-. (infix)| Floating-point subtraction.   
~-. -. (prefix)| Floating-point negation.  
*.| Floating-point multiplication.   
/.| Floating-point division.  
**| Floating-point exponentiation.  
@ | List concatenation.   
^ | String concatenation.   
! | Dereferencing (return the current contents of a reference).   
:=| Reference assignment (update the reference given as first argument with
the value of the second argument).  
= | Structural equality test.   
<> | Structural inequality test.   
== | Physical equality test.   
!= | Physical inequality test.   
< | Test “less than”.   
<= | Test “less than or equal”.   
> | Test “greater than”.   
>= | Test “greater than or equal”.   
&& &| Boolean conjunction.  
|| or| Boolean disjunction.  
  
### ﻿11.7.6 Objects

#### ﻿Object creation

When [class-path](names.html#class-path) evaluates to a class body, new
[class-path](names.html#class-path) evaluates to a new object containing the
instance variables and methods of this class.

# class of_list (lst : int list) = object val mutable l = lst method next = match l with | [] -> raise (Failure "empty list"); | h::t -> l <\- t; h end let a = new of_list [1; 1; 2; 3; 5; 8; 13] let b = new of_list;;

class of_list : int list -> object val mutable l : int list method next : int
end val a : of_list = <obj> val b : int list -> of_list = <fun>

When [class-path](names.html#class-path) evaluates to a class function, new
[class-path](names.html#class-path) evaluates to a function expecting the same
number of arguments and returning a new object of this class.

#### ﻿Immediate object creation

Creating directly an object through the object [class-
body](classes.html#class-body) end construct is operationally equivalent to
defining locally a class [class-name](names.html#class-name) = object [class-
body](classes.html#class-body) end —see sections
[11.9.2](classes.html#sss%3Aclass-body) and following for the syntax of
[class-body](classes.html#class-body)— and immediately creating a single
object from it by new [class-name](names.html#class-name).

# let o = object val secret = 99 val password = "unlock" method get guess = if
guess <> password then None else Some secret end;;

val o : < get : string -> int option > = <obj>

The typing of immediate objects is slightly different from explicitly defining
a class in two respects. First, the inferred object type may contain free type
variables. Second, since the class body of an immediate object will never be
extended, its self type can be unified with a closed object type.

#### ﻿Method invocation

The expression expr # [method-name](names.html#method-name) invokes the method
[method-name](names.html#method-name) of the object denoted by expr.

# class of_list (lst : int list) = object val mutable l = lst method next = match l with | [] -> raise (Failure "empty list"); | h::t -> l <\- t; h end let a = new of_list [1; 1; 2; 3; 5; 8; 13] let third = ignore a#next; ignore a#next; a#next;;

class of_list : int list -> object val mutable l : int list method next : int
end val a : of_list = <obj> val third : int = 2

If [method-name](names.html#method-name) is a polymorphic method, its type
should be known at the invocation site. This is true for instance if expr is
the name of a fresh object (let [ident](lex.html#ident) = new [class-
path](names.html#class-path) … ) or if there is a type constraint.
Principality of the derivation can be checked in the -principal mode.

#### ﻿Accessing and modifying instance variables

The instance variables of a class are visible only in the body of the methods
defined in the same class or a class that inherits from the class defining the
instance variables. The expression [inst-var-name](names.html#inst-var-name)
evaluates to the value of the given instance variable. The expression [inst-
var-name](names.html#inst-var-name) <- expr assigns the value of expr to the
instance variable [inst-var-name](names.html#inst-var-name), which must be
mutable. The whole expression [inst-var-name](names.html#inst-var-name) <-
expr evaluates to ().

# class of_list (lst : int list) = object val mutable l = lst method next = match l with (* access instance variable *) | [] -> raise (Failure "empty list"); | h::t -> l <\- t; h (* modify instance variable *) end;;

class of_list : int list -> object val mutable l : int list method next : int
end

#### ﻿Object duplication

An object can be duplicated using the library function Oo.copy (see module
[Oo](libref/Oo.html)). Inside a method, the expression {< [[inst-var-
name](names.html#inst-var-name) [= expr] { ; [inst-var-name](names.html#inst-
var-name) [= expr] }] >} returns a copy of self with the given instance
variables replaced by the values of the associated expressions. A single
instance variable name id stands for id = id. Other instance variables have
the same value in the returned object as in self.

# let o = object val secret = 99 val password = "unlock" method get guess = if
guess <> password then None else Some secret method with_new_secret s = {<
secret = s >} end;;

val o : < get : string -> int option; with_new_secret : int -> 'a > as 'a =
<obj>

### ﻿11.7.7 Coercions

Expressions whose type contains object or polymorphic variant types can be
explicitly coerced (weakened) to a supertype. The expression (expr :>
[typexpr](types.html#typexpr)) coerces the expression expr to type
[typexpr](types.html#typexpr). The expression (expr :
[typexpr](types.html#typexpr)1 :> [typexpr](types.html#typexpr)2) coerces the
expression expr from type [typexpr](types.html#typexpr)1 to type
[typexpr](types.html#typexpr)2.

The former operator will sometimes fail to coerce an expression expr from a
type [typ](types.html#typexpr)1 to a type [typ](types.html#typexpr)2 even if
type [typ](types.html#typexpr)1 is a subtype of type
[typ](types.html#typexpr)2: in the current implementation it only expands two
levels of type abbreviations containing objects and/or polymorphic variants,
keeping only recursion when it is explicit in the class type (for objects). As
an exception to the above algorithm, if both the inferred type of expr and
[typ](types.html#typexpr) are ground (_i.e._ do not contain type variables),
the former operator behaves as the latter one, taking the inferred type of
expr as [typ](types.html#typexpr)1. In case of failure with the former
operator, the latter one should be used.

It is only possible to coerce an expression expr from type
[typ](types.html#typexpr)1 to type [typ](types.html#typexpr)2, if the type of
expr is an instance of [typ](types.html#typexpr)1 (like for a type
annotation), and [typ](types.html#typexpr)1 is a subtype of
[typ](types.html#typexpr)2. The type of the coerced expression is an instance
of [typ](types.html#typexpr)2. If the types contain variables, they may be
instantiated by the subtyping algorithm, but this is only done after
determining whether [typ](types.html#typexpr)1 is a potential subtype of
[typ](types.html#typexpr)2. This means that typing may fail during this latter
unification step, even if some instance of [typ](types.html#typexpr)1 is a
subtype of some instance of [typ](types.html#typexpr)2. In the following
paragraphs we describe the subtyping relation used.

#### ﻿Object types

A fixed object type admits as subtype any object type that includes all its
methods. The types of the methods shall be subtypes of those in the supertype.
Namely,

< [met](names.html#method-name)1 : [typ](types.html#typexpr)1 ; … ;
[met](names.html#method-name)n : [typ](types.html#typexpr)n >

is a supertype of

< [met](names.html#method-name)1 : [typ](types.html#typexpr)′1 ; … ;
[met](names.html#method-name)n : [typ](types.html#typexpr)′n ;
[met](names.html#method-name)n+1 : [typ](types.html#typexpr)′n+1 ; … ;
[met](names.html#method-name)n+m : [typ](types.html#typexpr)′n+m [; ..] >

which may contain an ellipsis .. if every [typ](types.html#typexpr)i is a
supertype of the corresponding [typ](types.html#typexpr)′i.

A monomorphic method type can be a supertype of a polymorphic method type.
Namely, if [typ](types.html#typexpr) is an instance of
[typ](types.html#typexpr)′, then 'a1 … 'an . [typ](types.html#typexpr)′ is a
subtype of [typ](types.html#typexpr).

Inside a class definition, newly defined types are not available for
subtyping, as the type abbreviations are not yet completely defined. There is
an exception for coercing self to the (exact) type of its class: this is
allowed if the type of self does not appear in a contravariant position in the
class type, _i.e._ if there are no binary methods.

#### ﻿Polymorphic variant types

A polymorphic variant type [typ](types.html#typexpr) is a subtype of another
polymorphic variant type [typ](types.html#typexpr)′ if the upper bound of
[typ](types.html#typexpr) (_i.e._ the maximum set of constructors that may
appear in an instance of [typ](types.html#typexpr)) is included in the lower
bound of [typ](types.html#typexpr)′, and the types of arguments for the
constructors of [typ](types.html#typexpr) are subtypes of those in
[typ](types.html#typexpr)′. Namely,

[[<] `[C](names.html#constr-name)1 of [typ](types.html#typexpr)1 | … | `[C](names.html#constr-name)n of [typ](types.html#typexpr)n ]

which may be a shrinkable type, is a subtype of

[[>] `[C](names.html#constr-name)1 of [typ](types.html#typexpr)′1 | … | `[C](names.html#constr-name)n of [typ](types.html#typexpr)′n | `[C](names.html#constr-name)n+1 of [typ](types.html#typexpr)′n+1 | … | `[C](names.html#constr-name)n+m of [typ](types.html#typexpr)′n+m ]

which may be an extensible type, if every [typ](types.html#typexpr)i is a
subtype of [typ](types.html#typexpr)′i.

#### ﻿Variance

Other types do not introduce new subtyping, but they may propagate the
subtyping of their arguments. For instance, [typ](types.html#typexpr)1 *
[typ](types.html#typexpr)2 is a subtype of [typ](types.html#typexpr)′1 *
[typ](types.html#typexpr)′2 when [typ](types.html#typexpr)1 and
[typ](types.html#typexpr)2 are respectively subtypes of
[typ](types.html#typexpr)′1 and [typ](types.html#typexpr)′2. For function
types, the relation is more subtle: [typ](types.html#typexpr)1 ->
[typ](types.html#typexpr)2 is a subtype of [typ](types.html#typexpr)′1 ->
[typ](types.html#typexpr)′2 if [typ](types.html#typexpr)1 is a supertype of
[typ](types.html#typexpr)′1 and [typ](types.html#typexpr)2 is a subtype of
[typ](types.html#typexpr)′2. For this reason, function types are covariant in
their second argument (like tuples), but contravariant in their first
argument. Mutable types, like array or ref are neither covariant nor
contravariant, they are nonvariant, that is they do not propagate subtyping.

For user-defined types, the variance is automatically inferred: a parameter is
covariant if it has only covariant occurrences, contravariant if it has only
contravariant occurrences, variance-free if it has no occurrences, and
nonvariant otherwise. A variance-free parameter may change freely through
subtyping, it does not have to be a subtype or a supertype. For abstract and
private types, the variance must be given explicitly (see section
[11.8.1](typedecl.html#ss%3Atypedefs)), otherwise the default is nonvariant.
This is also the case for constrained arguments in type definitions.

### ﻿11.7.8 Local structure items

(General case introduced in OCaml 5.5, let open, let exception, and let module
were supported earlier.)

The form let [local-definition](modules.html#local-definition) in expr brings
the structure item (see [11.11.2](modules.html#ss%3Amexpr-structures)) [local-
definition](modules.html#local-definition) into scope during the evaluation of
expr.

This construction is equivalent to locally introducing the structure

struct [local-definition](modules.html#local-definition) let body = expr end

in the context of the let expression and returning the value of body as
result.

The rest of this section contains remarks and examples specific to particular
cases of this construction.

#### ﻿Local opens

The expressions let open [module-path](names.html#module-path) in expr and
[module-path](names.html#module-path).(expr) are strictly equivalent. These
constructions locally open the module referred to by the module path [module-
path](names.html#module-path) in the respective scope of the expression expr.

# let map_3d_matrix f m = let open Array in map (map (map f)) m let
map_3d_matrix' f = Array.(map (map (map f)));;

val map_3d_matrix : ('a -> 'b) -> 'a array array array -> 'b array array array
= <fun> val map_3d_matrix' : ('a -> 'b) -> 'a array array array -> 'b array
array array = <fun>

When the body of a local open expression is delimited by [ ], [| |], or { },
the parentheses can be omitted. For expression, parentheses can also be
omitted for {< >}. For example, [module-path](names.html#module-path).[expr]
is equivalent to [module-path](names.html#module-path).([expr]), and [module-
path](names.html#module-path).[| expr |] is equivalent to [module-
path](names.html#module-path).([| expr |]).

# let vector = Random.[|int 255; int 255; int 255; int 255|];;

val vector : int array = [|220; 90; 247; 144|]

#### ﻿Local modules

The expression let [module-definition](modules.html#module-definition) in expr
locally binds the module definition [module-definition](modules.html#module-
definition) during the evaluation of the expression expr. It then returns the
value of expr. For example:

# let remove_duplicates comparison_fun string_list = let module StringSet =
Set.Make(struct type t = string let compare = comparison_fun end) in
StringSet.elements (List.fold_right StringSet.add string_list
StringSet.empty);;

val remove_duplicates : (string -> string -> int) -> string list -> string
list = <fun>

#### ﻿Local exceptions

(Introduced in OCaml 4.04)

It is possible to define local exceptions in expressions: let exception
[constr-decl](typedecl.html#constr-decl) in expr .

# let map_empty_on_negative f l = let exception Negative in let aux x = if x <
0 then raise Negative else f x in try List.map aux l with Negative -> [];;

val map_empty_on_negative : (int -> 'a) -> int list -> 'a list = <fun>

The syntactic scope of the exception constructor is the inner expression, but
nothing prevents exception values created with this constructor from escaping
this scope. Two executions of the definition above result in two incompatible
exception constructors (as for any exception definition). For instance:

# let gen () = let exception A in A let () = assert(gen () = gen ());;

Exception: Assert_failure ("expr.etex", 3, 9).

Extensible variant types (see [12.14](extensiblevariants.html#s%3Aextensible-
variants)) can also be introduced in this way. The example below exhibits a
function that uses a local effect to convert an iterator into a sequence
(“inversion of control”).

# let invert (type a) ~(iter : (a -> unit) -> unit) : a Seq.t = let type _ Effect.t += Yield : a -> unit Effect.t in let yield v = Effect.perform (Yield v) in fun () -> match iter yield with | () -> Seq.Nil | effect Yield v, k -> Seq.Cons (v, Effect.Deep.continue k) ;;

val invert : iter:(('a -> unit) -> unit) -> 'a Seq.t = <fun>

#### ﻿Local types

The form let [type-definition](typedecl.html#type-definition) in expr
introduces a type (or a collection of mutually recursive types) in the scope
of an expression:

# let f x y = let type t = {x: float; y: float} in let norm p = p.x *. p.x +.
p.y *. p.y in norm {x; y} ;;

val f : float -> float -> float = <fun>

The compiler checks that values created from this type do not escape this
scope:

# let f x y = let type t = {x: float; y: float} in let twice p = {x = p.x +.
p.x; y = p.y +. p.y} in twice {x; y} ;;

Error: This expression has type t but an expression was expected of type 'a
The type constructor t would escape its scope

### ﻿11.7.9 Other

#### ﻿Assertion checking

OCaml supports the assert construct to check debugging assertions. The
expression assert expr evaluates the expression expr and returns () if expr
evaluates to true. If it evaluates to false the exception Assert_failure is
raised with the source file name and the location of expr as arguments.
Assertion checking can be turned off with the -noassert compiler option. In
this case, expr is not evaluated at all.

# let f a b c = assert (a <= b && b <= c); (b -. a) /. (c -. b);;

val f : float -> float -> float -> float = <fun>

As a special case, assert false is reduced to raise (Assert_failure ...),
which gives it a polymorphic type. This means that it can be used in place of
any expression (for example as a branch of any pattern-matching). It also
means that the assert false “assertions” cannot be turned off by the -noassert
option.

# let min_known_nonempty = function | [] -> assert false | l -> List.hd (List.sort compare l);;

val min_known_nonempty : 'a list -> 'a = <fun>

#### ﻿Lazy expressions

The expression lazy expr returns a value v of type Lazy.t that encapsulates
the computation of expr. The argument expr is not evaluated at this point in
the program. Instead, its evaluation will be performed the first time the
function Lazy.force is applied to the value v, returning the actual value of
expr. Subsequent applications of Lazy.force to v do not evaluate expr again.
Applications of Lazy.force may be implicit through pattern matching (see
[11.6](patterns.html#sss%3Apat-lazy)).

# let lazy_greeter = lazy (print_string "Hello, World!\n");;

val lazy_greeter : unit lazy_t = <lazy>

# Lazy.force lazy_greeter;;

Hello, World! \- : unit = ()

* * *

[![Previous](previous_motif.svg)](patterns.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](typedecl.html)

