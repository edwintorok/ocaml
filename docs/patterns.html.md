[![Previous](previous_motif.svg)](const.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](expr.html)

* * *

## ﻿11.6 Patterns

| pattern| ::=|  [value-name](names.html#value-name)  
---|---|---  
 | ∣|  _  
 | ∣|  [constant](const.html#constant)  
 | ∣|  pattern as [value-name](names.html#value-name)  
 | ∣|  ( pattern )  
 | ∣|  ( pattern : [typexpr](types.html#typexpr) )  
 | ∣|  pattern | pattern  
 | ∣|  [constr](names.html#constr) pattern  
 | ∣|  `[tag-name](names.html#tag-name) pattern  
 | ∣|  #[typeconstr](names.html#typeconstr)  
 | ∣|  pattern { , pattern }+  
 | ∣|  { [field](names.html#field) [: [typexpr](types.html#typexpr)] [= pattern]{ ; [field](names.html#field) [: [typexpr](types.html#typexpr)] [= pattern] } [; _ ] [ ; ] }  
 | ∣|  [ pattern { ; pattern } [ ; ] ]  
 | ∣|  pattern :: pattern  
 | ∣|  [| pattern { ; pattern } [ ; ] |]  
 | ∣|  [char-literal](lex.html#char-literal) .. [char-literal](lex.html#char-literal)  
 | ∣|  lazy pattern  
 | ∣|  exception pattern  
 | ∣|  [module-path](names.html#module-path) .( pattern )  
 | ∣|  [module-path](names.html#module-path) .[ pattern ]  
 | ∣|  [module-path](names.html#module-path) .[| pattern |]  
 | ∣|  [module-path](names.html#module-path) .{ pattern }  
  
See also the following language extensions: [first-class
modules](firstclassmodules.html#s%3Afirst-class-modules),
[attributes](attributes.html#s%3Aattributes), [extension
nodes](extensionnodes.html#s%3Aextension-nodes), [effect
handlers](effects.html#s%3Aeffect-handlers), [type-directed disambiguation of
array literals](arrayliterals.html#s%3Aarray-literals) and [labeled
tuples](labeledtuples.html#s%3Alabeled-tuples).

The table below shows the relative precedences and associativity of operators
and non-closed pattern constructions. The constructions with higher
precedences come first.

Operator| Associativity  
---|---  
..| –  
lazy (see section 11.6)| –  
Constructor application, Tag application| right  
::| right  
,| –  
|| left  
as| –  
  
Patterns are templates that allow selecting data structures of a given shape,
and binding identifiers to components of the data structure. This selection
operation is called pattern matching; its outcome is either “this value does
not match this pattern”, or “this value matches this pattern, resulting in the
following bindings of names to values”.

#### ﻿Variable patterns

A pattern that consists in a value name matches any value, binding the name to
the value. The pattern _ also matches any value, but does not bind any name.

# let is_empty = function | [] -> true | _ :: _ -> false;;

val is_empty : 'a list -> bool = <fun>

Patterns are _linear_ : a variable cannot be bound several times by a given
pattern. In particular, there is no way to test for equality between two parts
of a data structure using only a pattern:

# let pair_equal = function | x, x -> true | x, y -> false;;

Error: Variable x is bound several times in this matching

However, we can use a when guard for this purpose:

# let pair_equal = function | x, y when x = y -> true | _ -> false;;

val pair_equal : 'a * 'a -> bool = <fun>

#### ﻿Constant patterns

A pattern consisting in a constant matches the values that are equal to this
constant.

# let bool_of_string = function | "true" -> true | "false" -> false | _ -> raise (Invalid_argument "bool_of_string");;

val bool_of_string : string -> bool = <fun>

#### ﻿Alias patterns

The pattern pattern1 as [value-name](names.html#value-name) matches the same
values as pattern1. If the matching against pattern1 is successful, the name
[value-name](names.html#value-name) is bound to the matched value, in addition
to the bindings performed by the matching against pattern1.

# let sort_pair ((x, y) as p) = if x <= y then p else (y, x);;

val sort_pair : 'a * 'a -> 'a * 'a = <fun>

#### ﻿Parenthesized patterns

The pattern ( pattern1 ) matches the same values as pattern1. A type
constraint can appear in a parenthesized pattern, as in ( pattern1 :
[typexpr](types.html#typexpr) ). This constraint forces the type of pattern1
to be compatible with [typexpr](types.html#typexpr).

# let int_triple_is_ordered ((a, b, c) : int * int * int) = a <= b && b <= c;;

val int_triple_is_ordered : int * int * int -> bool = <fun>

#### ﻿“Or” patterns

The pattern pattern1 | pattern2 represents the logical “or” of the two patterns pattern1 and pattern2. A value matches pattern1 | pattern2 if it matches pattern1 or pattern2. The two sub-patterns pattern1 and pattern2 must bind exactly the same identifiers to values having the same types. Matching is performed from left to right. More precisely, in case some value v matches pattern1 | pattern2, the bindings performed are those of pattern1 when v matches pattern1. Otherwise, value v matches pattern2 whose bindings are performed.

# type shape = Square of float | Rect of (float * float) | Circle of float let is_rectangular = function | Square _ | Rect _ -> true | Circle _ -> false;;

type shape = Square of float | Rect of (float * float) | Circle of float val is_rectangular : shape -> bool = <fun>

#### ﻿Variant patterns

The pattern [constr](names.html#constr) ( pattern1 , … , patternn ) matches
all variants whose constructor is equal to [constr](names.html#constr), and
whose arguments match pattern1 … patternn. It is a type error if n is not the
number of arguments expected by the constructor.

The pattern [constr](names.html#constr) _ matches all variants whose
constructor is [constr](names.html#constr).

# type 'a tree = Lf | Br of 'a tree * 'a * 'a tree let rec total = function | Br (l, x, r) -> total l + x + total r | Lf -> 0;;

type 'a tree = Lf | Br of 'a tree * 'a * 'a tree val total : int tree -> int = <fun>

The pattern pattern1 :: pattern2 matches non-empty lists whose heads match
pattern1, and whose tails match pattern2.

The pattern [ pattern1 ; … ; patternn ] matches lists of length n whose
elements match pattern1 …patternn, respectively. This pattern behaves like
pattern1 :: … :: patternn :: [].

# let rec destutter = function | [] -> [] | [a] -> [a] | a :: b :: t -> if a = b then destutter (b :: t) else a :: destutter (b :: t);;

val destutter : 'a list -> 'a list = <fun>

#### ﻿Polymorphic variant patterns

The pattern `[tag-name](names.html#tag-name) pattern1 matches all polymorphic
variants whose tag is equal to [tag-name](names.html#tag-name), and whose
argument matches pattern1.

# let rec split = function | [] -> ([], []) | h :: t -> let ss, gs = split t in match h with | `Sheep _ as s -> (s :: ss, gs) | `Goat _ as g -> (ss, g :: gs);;

val split : [< `Goat of 'a | `Sheep of 'b ] list -> [> `Sheep of 'b ] list * [> `Goat of 'a ] list = <fun>

#### ﻿Polymorphic variant abbreviation patterns

If the type [('a,'b,…)] [typeconstr](names.html#typeconstr) = [ `[tag-name](names.html#tag-name)1 [typexpr](types.html#typexpr)1 | … | `[tag-name](names.html#tag-name)n [typexpr](types.html#typexpr)n] is defined, then the pattern #[typeconstr](names.html#typeconstr) is a shorthand for the following or-pattern: ( `[tag-name](names.html#tag-name)1(_ : [typexpr](types.html#typexpr)1) | … | `[tag-name](names.html#tag-name)n(_ : [typexpr](types.html#typexpr)n)). It matches all values of type [< [typeconstr](names.html#typeconstr) ].

# type 'a rectangle = [`Square of 'a | `Rectangle of 'a * 'a] type 'a shape = [`Circle of 'a | 'a rectangle] let try_rectangle = function | #rectangle as r -> Some r | `Circle _ -> None;;

type 'a rectangle = [ `Rectangle of 'a * 'a | `Square of 'a ] type 'a shape = [ `Circle of 'a | `Rectangle of 'a * 'a | `Square of 'a ] val try_rectangle : [< `Circle of 'a | `Rectangle of 'b * 'b | `Square of 'b ] -> [> `Rectangle of 'b * 'b | `Square of 'b ] option = <fun>

#### ﻿Tuple patterns

The pattern pattern1 , … , patternn matches n-tuples whose components match
the patterns pattern1 through patternn. That is, the pattern matches the tuple
values (v1, …, vn) such that patterni matches vi for i = 1,… , n.

# let vector (x0, y0) (x1, y1) = (x1 -. x0, y1 -. y0);;

val vector : float * float -> float * float -> float * float = <fun>

#### ﻿Record patterns

The pattern { [field](names.html#field)1 [= pattern1] ; … ;
[field](names.html#field)n [= patternn] } matches records that define at least
the fields [field](names.html#field)1 through [field](names.html#field)n, and
such that the value associated to [field](names.html#field)i matches the
pattern patterni, for i = 1,… , n. A single identifier
[field](names.html#field)k stands for [field](names.html#field)k =
[field](names.html#field)k , and a single qualified identifier [module-
path](names.html#module-path) . [field](names.html#field)k stands for [module-
path](names.html#module-path) . [field](names.html#field)k =
[field](names.html#field)k . The record value can define more fields than
[field](names.html#field)1 …[field](names.html#field)n; the values associated
to these extra fields are not taken into account for matching. Optionally, a
record pattern can be terminated by ; _ to convey the fact that not all fields
of the record type are listed in the record pattern and that it is
intentional. Optional type constraints can be added field by field with {
[field](names.html#field)1 : [typexpr](types.html#typexpr)1 = pattern1 ;…
;[field](names.html#field)n : [typexpr](types.html#typexpr)n = patternn } to
force the type of [field](names.html#field)k to be compatible with
[typexpr](types.html#typexpr)k.

# let bytes_allocated {Gc.minor_words = minor; Gc.major_words = major;
Gc.promoted_words = prom; _} = (Sys.word_size / 4) * int_of_float (minor +.
major -. prom);;

val bytes_allocated : Gc.stat -> int = <fun>

#### ﻿Array patterns

The pattern [| pattern1 ; … ; patternn |] matches arrays of length n such that
the i-th array element matches the pattern patterni, for i = 1,… , n.

# let matrix3_is_symmetric = function | [|[|_; b; c|]; [|d; _; f|]; [|g; h; _|]|] -> b = d && c = g && f = h | _ -> failwith "matrix3_is_symmetric: not a 3x3 matrix";;

val matrix3_is_symmetric : 'a array array -> bool = <fun>

#### ﻿Range patterns

The pattern ' c ' .. ' d ' is a shorthand for the pattern

' c ' | ' c1 ' | ' c2 ' | … | ' cn ' | ' d '

where c1, c2, …, cn are the characters that occur between c and d in the ASCII
character set. For instance, the pattern '0'..'9' matches all characters that
are digits.

# type char_class = Uppercase | Lowercase | Digit | Other let classify_char = function | 'A'..'Z' -> Uppercase | 'a'..'z' -> Lowercase | '0'..'9' -> Digit | _ -> Other;;

type char_class = Uppercase | Lowercase | Digit | Other val classify_char : char -> char_class = <fun>

#### ﻿Lazy patterns

(Introduced in Objective Caml 3.11)

The pattern lazy pattern matches a value v of type Lazy.t, provided pattern
matches the result of forcing v with Lazy.force. A successful match of a
pattern containing lazy sub-patterns forces the corresponding parts of the
value being matched, even those that imply no test such as lazy [value-
name](names.html#value-name) or lazy _. Matching a value with a [pattern-
matching](expr.html#pattern-matching) where some patterns contain lazy sub-
patterns may imply forcing parts of the value, even when the pattern selected
in the end has no lazy sub-pattern.

# let force_opt = function | Some (lazy n) -> n | None -> 0;;

val force_opt : int lazy_t option -> int = <fun>

For more information, see the description of module Lazy in the standard
library (module [Lazy](libref/Lazy.html)).

#### ﻿Exception patterns

(Introduced in OCaml 4.02)

A new form of exception pattern, exception pattern , is allowed only as a
toplevel pattern or inside a toplevel or-pattern under a match...with pattern-
matching (other occurrences are rejected by the type-checker).

Cases with such a toplevel pattern are called “exception cases”, as opposed to
regular “value cases”. Exception cases are applied when the evaluation of the
matched expression raises an exception. The exception value is then matched
against all the exception cases and re-raised if none of them accept the
exception (as with a try...with block). Since the bodies of all exception and
value cases are outside the scope of the exception handler, they are all
considered to be in tail-position: if the match...with block itself is in tail
position in the current function, any function call in tail position in one of
the case bodies results in an actual tail call.

A pattern match must contain at least one value case. It is an error if all
cases are exceptions, because there would be no code to handle the return of a
value.

# let find_opt p l = match List.find p l with | exception Not_found -> None | x -> Some x;;

val find_opt : ('a -> bool) -> 'a list -> 'a option = <fun>

#### ﻿Local opens for patterns

(Introduced in OCaml 4.04)

For patterns, local opens are limited to the [module-path](names.html#module-
path).(pattern) construction. This construction locally opens the module
referred to by the module path [module-path](names.html#module-path) in the
scope of the pattern pattern.

When the body of a local open pattern is delimited by [ ], [| |], or { }, the
parentheses can be omitted. For example, [module-path](names.html#module-
path).[pattern] is equivalent to [module-path](names.html#module-
path).([pattern]), and [module-path](names.html#module-path).[| pattern |] is
equivalent to [module-path](names.html#module-path).([| pattern |]).

# let bytes_allocated Gc.{minor_words; major_words; promoted_words; _} =
(Sys.word_size / 4) * int_of_float (minor_words +. major_words -.
promoted_words);;

val bytes_allocated : Gc.stat -> int = <fun>

* * *

[![Previous](previous_motif.svg)](const.html)
[![Up](contents_motif.svg)](language.html)
[![Next](next_motif.svg)](expr.html)

