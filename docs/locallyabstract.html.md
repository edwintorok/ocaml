[![Previous](previous_motif.svg)](privatetypes.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](firstclassmodules.html)

* * *

## ﻿12.4 Locally abstract types

(Introduced in OCaml 3.12, short syntax added in 4.03)

| [parameter](expr.html#parameter)| ::=|  ...  
---|---|---  
 | ∣|  ( type { [typeconstr-name](names.html#typeconstr-name) }+ )  
  
The expression fun ( type [typeconstr-name](names.html#typeconstr-name) ) ->
[expr](expr.html#expr) introduces a type constructor named [typeconstr-
name](names.html#typeconstr-name) which is considered abstract in the scope of
the sub-expression, but then replaced by a fresh type variable. Note that
contrary to what the syntax could suggest, the expression fun ( type
[typeconstr-name](names.html#typeconstr-name) ) -> [expr](expr.html#expr)
itself does not suspend the evaluation of [expr](expr.html#expr) as a regular
abstraction would. The syntax has been chosen to fit nicely in the context of
function declarations, where it is generally used. It is possible to freely
mix regular function parameters with pseudo type parameters, as in:

let f = fun (type t) (foo : t list) -> …

and even use the alternative syntax for declaring functions:

let f (type t) (foo : t list) = …

If several locally abstract types need to be introduced, it is possible to use
the syntax fun ( type [typeconstr-name](names.html#typeconstr-name)1 …
[typeconstr-name](names.html#typeconstr-name)n ) -> [expr](expr.html#expr) as
syntactic sugar for fun ( type [typeconstr-name](names.html#typeconstr-name)1
) -> … -> fun ( type [typeconstr-name](names.html#typeconstr-name)n ) ->
[expr](expr.html#expr). For instance,

let f = fun (type t u v) -> fun (foo : (t * u * v) list) -> … let f' (type t u
v) (foo : (t * u * v) list) = …

This construction is useful because the type constructors it introduces can be
used in places where a type variable is not allowed. For instance, one can use
it to define an exception in a local module within a polymorphic function.

let f (type t) () = let module M = struct exception E of t end in (fun x -> M.E x), (function M.E x -> Some x | _ -> None)

Here is another example:

let sort_uniq (type s) (cmp : s -> s -> int) = let module S = Set.Make(struct
type t = s let compare = cmp end) in fun l -> S.elements (List.fold_right
S.add l S.empty)

It is also extremely useful for first-class modules (see section
[12.5](firstclassmodules.html#s%3Afirst-class-modules)) and generalized
algebraic datatypes (GADTs: see section [12.10](gadts.html#s%3Agadts)).

##### ﻿Polymorphic syntax

(Introduced in OCaml 4.00)

| [let-binding](expr.html#let-binding)| ::=|  ...  
---|---|---  
 | ∣|  [value-name](names.html#value-name) : type { [typeconstr-name](names.html#typeconstr-name) }+ . [typexpr](types.html#typexpr) = [expr](expr.html#expr)  
  
[class-field](classes.html#class-field)| ::=|  ...  
 | ∣|  method [private] [method-name](names.html#method-name) : type { [typeconstr-name](names.html#typeconstr-name) }+ . [typexpr](types.html#typexpr) = [expr](expr.html#expr)  
 | ∣|  method! [private] [method-name](names.html#method-name) : type { [typeconstr-name](names.html#typeconstr-name) }+ . [typexpr](types.html#typexpr) = [expr](expr.html#expr)  
  
The (type [typeconstr-name](names.html#typeconstr-name)) syntax construction
by itself does not make polymorphic the type variable it introduces, but it
can be combined with explicit polymorphic annotations where needed. The above
rule is provided as syntactic sugar to make this easier:

let rec f : type t1 t2. t1 * t2 list -> t1 = …

is automatically expanded into

let rec f : 't1 't2. 't1 * 't2 list -> 't1 = fun (type t1) (type t2) -> ( … :
t1 * t2 list -> t1)

This syntax can be very useful when defining recursive functions involving
GADTs, see the section [12.10](gadts.html#s%3Agadts) for a more detailed
explanation.

The same feature is provided for method definitions.

* * *

[![Previous](previous_motif.svg)](privatetypes.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](firstclassmodules.html)

