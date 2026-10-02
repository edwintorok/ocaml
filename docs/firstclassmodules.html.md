[![Previous](previous_motif.svg)](locallyabstract.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](moduletypeof.html)

* * *

## ﻿12.5 Module-dependent functions and first-class modules

  * [12.5.1 Introduction](firstclassmodules.html#ss%3Afst-mod-intro)
  * [12.5.2 Reference](firstclassmodules.html#ss%3Afst-mod-reference)

(First-class modules were introduced in OCaml 3.12; pattern syntax and package
type inference in 4.00; structural comparison of package types in 4.02; fewer
parentheses required starting from 4.05.  
Module-dependent functions were introduced in 5.5.)

Module-dependent functions and first-class modules make it possible to
manipulate modules as values, in particular to accept modules as function
parameters.

### ﻿12.5.1 Introduction

##### ﻿Module-dependent functions: functions parameterized over a module

One can write a function sort0 that sorts elements by adding them into a
sorted set, and then reads them back in order:

let sort0 (type a) cmp li = let module M = struct type t = a let compare = cmp
end in let module MSet = Stdlib.Set.Make(M) in MSet.elements (List.fold_right
MSet.add li MSet.empty) let example = sort0 Int.compare [3; 1; 2]

val sort0 : ('a -> 'a -> int) -> 'a list -> 'a list = <fun> val example : int
list = [1; 2; 3]

Using module-dependent functions, it is also possible to express sort as a
function parameterized over an ordered-set module. This lets callers choose
their ordered-set implementation, which may be specialized for their type; for
example sets of integers can be represented with bitsets, or with compact
representations of dense intervals.

let sort (module MSet : Set.S) li = MSet.elements (List.fold_right MSet.add li
MSet.empty)

val sort : (module MSet : Set.S) -> MSet.elt list -> MSet.elt list = <fun>

The declaration of sort uses the pattern syntax (module M : S), which allows
function parameters to be modules instead of ordinary values. We call sort a
_module-dependent_ function because in its type, (module MSet : Set.S) ->
MSet.elt list -> MSet.elt list, the module parameter appears in the right-
hand-side (return type) of the arrow (module MSet : Set.S) -> ..., via
occurrences of the type MSet.elt.

To apply the sort function, we use the construction (module M) to provide the
argument, or (module M : S) to be explicit about the intended signature.

module ISetIncr = Set.Make(Int) module ISetDecr = Set.Make(struct type t = int
let compare i1 i2 = Int.compare i2 i1 end)

# let example = sort (module ISetIncr) [3; 1; 2];;

val example : ISetIncr.elt list = [1; 2; 3]

# let example = sort (module ISetDecr) [3; 1; 2];;

val example : ISetDecr.elt list = [3; 2; 1]

This provides a lightweight alternative to functors. Indeed, the sort function
could also be expressed using a Sort functor:

module Sort (MSet : Set.S) = struct let f li = MSet.elements (List.fold_right
MSet.add li MSet.empty) end

module Sort : (MSet : Set.S) -> sig val f : MSet.elt list -> MSet.elt list end

# let module S = Sort(ISetDecr) in S.f [3; 1; 2];;

\- : ISetDecr.elt list = [3; 2; 1]

##### ﻿Use-case: abstracting over algebraic structures

Module-dependent functions offer a nice way to implement code that is
parametric over families of type structures, for example over any monad.

module type Monad = sig type 'a t val return : 'a -> 'a t val bind : 'a t -> ('a -> 'b t) -> 'b t end let mapM (module M : Monad) (f : 'a -> 'b M.t) (li : 'a list) : 'b list M.t = let ( let* ) = M.bind in let rec loop = function | [] -> M.return [] | x::xs -> let* y = f x in let* ys = loop xs in M.return (y :: ys) in loop li (* Example use-case: a map on the Result monad *) let map_result (type e) : ('a -> ('b, e) result) -> 'a list -> ('b list, e) result = let module R = struct type 'a t = ('a, e) result let return = Result.ok let bind = Result.bind end in mapM (module R)

##### ﻿First-class modules

In the function application sort (module ISetIncr) from our example above, we
say that the module argument is _static_ : it is known at compile-time.

First-class modules let you build _dynamic_ values that represent modules,
where the choice of module depends on runtime computations. If M is a module
of signature S, then (module M : S) is an expression of type (module S), we
say that it “packs” the module M as a value.

A typical use of first-class modules is to select at run-time among several
implementations of a signature. Each implementation is a structure that we can
pack into a first-class module, then store in a data structure such as a hash
table:

type picture = … module type DEVICE = sig val draw : picture -> unit … end let
devices : (string, (module DEVICE)) Hashtbl.t = Hashtbl.create 17 module SVG =
struct … end let _ = Hashtbl.add devices "SVG" (module SVG : DEVICE) module
PDF = struct … end let _ = Hashtbl.add devices "PDF" (module PDF : DEVICE)

The module expression (val e : S) can then _unpack_ a packed-module value (e :
(module S)) back into a module. In our example, one implementation can be
selected based on command-line arguments:

let parse_cmdline () = … module Device = (val (let device_name = parse_cmdline
() in try Hashtbl.find devices device_name with Not_found -> Printf.eprintf
"Unknown device %s\n" device_name; exit 2) : DEVICE)

Alternatively, the selection can be performed within a function:

let draw_using_device device_name picture = let module Device = (val
(Hashtbl.find devices device_name) : DEVICE) in Device.draw picture (* or,
equivalently *) let draw_using_device device_name picture = let (module Device
: DEVICE) = Hashtbl.find devices device_name in Device.draw picture

##### ﻿Limitation: selecting a module at runtime

There is a restriction on module-dependent functions fun (module A : S) ->
...: if the type of the body of the function (the ...) _depends_ on the module
argument A, then this function is only allowed to take static module arguments
of the form (module M : S), rather than arbitrary expressions of type (module
S). There is no such restriction if the type of the body does not mention A,
or if the type-checker can remove the occurrences of A by inlining type
equalities (for example when A.t equals int).

Our sort function of Paragraph 12.5.1 is such a module-dependent function: its
type is (module MSet : Set.S) -> MSet.elt list -> MSet.elt list, where the
module MSet is used on the right of the arrow (module MSet : Set.S) -> ....
The following example is rejected:

let sort_order = `Decr

let wrong = sort (match sort_order with | `Incr -> (module ISetIncr) | `Decr -> (module ISetDecr)) [2; 4]

Error: This expression has type (module MSet : Set.S) -> MSet.elt list ->
MSet.elt list but an expression was expected of type (module Set.S) -> 'a The
module MSet would escape its scope This function is module-dependent. The
dependency is preserved when the function is passed a static module argument
(module M : S) or (module M). Its argument here is not static, so the type-
checker tried instead to change the function type to be non-dependent.

In some cases, including this example, it is possible to rewrite the code to
use a static module argument again:

let okay = let m : (module Set.S with type elt = int) = match sort_order with | `Incr -> (module ISetIncr) | `Decr -> (module ISetDecr) in let module MSet = (val m) in sort (module MSet) [2; 4]

val okay : int list = [4; 2]

Notice that MSet.elt cannot occur in the type of okay, as the module MSet is
only defined locally. In this example the return type of sort does mention
MSet.elt, but this type is equal to int so it can be simplified away.

Finally, it is also possible to remove the dependency from the definition of
sort, by replacing the argument signature Set.S with the signature Set.S with
type elt = a, which uses a locally abstract type (type a) (See
[12.4](locallyabstract.html#s%3Alocally-abstract)). This was the only approach
available before module-dependent functions were introduced in the language,
but it is less flexible as it requires changing the function definition and
not just the call-site.

let sort_nondep (type a) (module MSet : Set.S with type elt = a) (li : a list) = MSet.elements (List.fold_right MSet.add li MSet.empty) let also_okay = sort_nondep (match sort_order with | `Incr -> (module ISetIncr) | `Decr -> (module ISetDecr)) [2; 4]

val sort_nondep : (module MSet : Set.S with type elt = 'a) -> 'a list ->
MSet.elt list = <fun> val also_okay : int list = [4; 2]

Note that removing dependencies using (type a) like this can only be done for
non-parameterized types like elt, not with parameterized types like 'a t;
there is no corresponding (type 'a t) abstraction. It would not be possible
for the mapM example above, which has a dependency on a module containing a
parameterized type 'a M.t, and thus cannot be passed dynamically-selected
module arguments.

##### ﻿Limitation: n-ary applications

The following example fails, where sort is our module-dependent function from
before:

let sort (module MSet : Set.S) li = MSet.elements (List.fold_right MSet.add li
MSet.empty) let wrong = Fun.id sort (module ISetIncr) [2; 3]

Error: The value sort has type (module MSet : Set.S) -> MSet.elt list ->
MSet.elt list but an expression was expected of type (module Set.S) -> 'a ->
'b The module MSet would escape its scope

The problem comes from subtle details in the type-checking of n-ary function
applications. This is checked as Fun.id to which three parameters are passed,
and only the type of Fun.id (not its arguments) is used to resolve the module
application, so no module-dependent function type is known at that point.

The example can be fixed by first applying Fun.id sort, and then passing the
module argument in a separate application. Then the module-dependent type of
Fun.id sort will be used to check the module application. This can be done by
simply adding extra parentheses:

let fixed = (Fun.id sort) (module ISetIncr) [2; 3]

val fixed : ISetIncr.elt list = [2; 3]

(Explicitly annotating the type of ‘Fun.id‘ with a module-dependent function
type would also work.)

##### ﻿Compatibility

Before OCaml 5.5, module-dependent functions were not supported. One could use
first-class modules, but functions taking a first-class module had to be non-
dependent, so this (type a) workaround was often used.

### ﻿12.5.2 Reference

| [typexpr](types.html#typexpr)| ::=|  ...  
---|---|---  
 | ∣|  (module package-type)  
 | ∣|  (module [module-name](names.html#module-name) : package-type) -> [typexpr](types.html#typexpr)  
  
[module-expr](modules.html#module-expr)| ::=|  ...  
 | ∣|  (val [expr](expr.html#expr) [: package-type])  
  
[expr](expr.html#expr)| ::=|  ...  
 | ∣|  (module [module-expr](modules.html#module-expr) [: package-type])  
  
[pattern](patterns.html#pattern)| ::=|  ...  
 | ∣|  (module [module-name](names.html#module-name) [: package-type])  
  
package-type| ::=|  [modtype-path](names.html#modtype-path)  
 | ∣|  [modtype-path](names.html#modtype-path) with package-constraint { and package-constraint }   
  
package-constraint| ::=|  type [typeconstr](names.html#typeconstr) =
[typexpr](types.html#typexpr)  
  
  
The expression ( module [module-expr](modules.html#module-expr) : package-type
) converts the module (structure or functor) denoted by module expression
[module-expr](modules.html#module-expr) to a value of the core language that
packs this module. The type of this core language value is ( module package-
type ). The package-type annotation can be omitted if it can be inferred from
the context.

Conversely, the module expression ( val [expr](expr.html#expr) : package-type
) evaluates the core language expression [expr](expr.html#expr) to a value,
which must have type module package-type, and extracts the module that was
encapsulated in this value. Again package-type can be omitted if the type of
[expr](expr.html#expr) is known. If the module expression is already
parenthesized, like the arguments of functors are, no additional parens are
needed: Map.Make(val key).

The pattern ( module [module-name](names.html#module-name) : package-type )
matches a package with type package-type and binds it to [module-
name](names.html#module-name). It is not allowed in toplevel let bindings. A
function whose parameter has this exact pattern can be module-dependent. Again
package-type can be omitted if it can be inferred from the enclosing pattern.

The package-type syntactic class appearing in the ( module package-type ) type
expression, in ( module [module-name](names.html#module-name) : package-type )
-> [typexpr](types.html#typexpr) type expression and in the annotated forms
represents a subset of module types. This subset consists of named module
types with optional constraints of a limited form: only non-parameterized
types can be specified.

For type-checking purposes (and starting from OCaml 4.02), package types are
compared using the structural comparison of module types.

When typechecking we also consider ( module [module-name](names.html#module-
name) : package-type ) -> [typexpr](types.html#typexpr) and ( module package-
type ) -> [typexpr](types.html#typexpr) to be identical when [module-
name](names.html#module-name) can be erased from
[typexpr](types.html#typexpr).

In general, the module expression ( val [expr](expr.html#expr) : package-type
) cannot be used in the body of a functor, because this could cause
unsoundness in conjunction with applicative functors. Since OCaml 4.02, this
is relaxed in two ways: if package-type does not contain nominal type
declarations (_i.e._ types that are created with a proper identity), then this
expression can be used anywhere, and even if it contains such types it can be
used inside the body of a generative functor, described in section
[12.15](generativefunctors.html#s%3Agenerative-functors). It can also be used
anywhere in the context of a local module binding let module [module-
name](names.html#module-name) = ( val [expr](expr.html#expr)1 : package-type )
in [expr](expr.html#expr)2.

* * *

[![Previous](previous_motif.svg)](locallyabstract.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](moduletypeof.html)

