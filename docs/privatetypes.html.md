[![Previous](previous_motif.svg)](recursivemodules.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](locallyabstract.html)

* * *

## ﻿12.3 Private types

  * [12.3.1 Private variant and record types](privatetypes.html#ss%3Aprivate-types-variant)
  * [12.3.2 Private type abbreviations](privatetypes.html#ss%3Aprivate-types-abbrev)
  * [12.3.3 Private row types](privatetypes.html#ss%3Aprivate-rows)

Private type declarations in module signatures, of the form type t = private
..., enable libraries to reveal some, but not all aspects of the
implementation of a type to clients of the library. In this respect, they
strike a middle ground between abstract type declarations, where no
information is revealed on the type implementation, and data type definitions
and type abbreviations, where all aspects of the type implementation are
publicized. Private type declarations come in three flavors: for variant and
record types (section 12.3.1), for type abbreviations (section 12.3.2), and
for row types (section 12.3.3).

### ﻿12.3.1 Private variant and record types

(Introduced in Objective Caml 3.07)

| [type-representation](typedecl.html#type-representation)| ::=|  ...  
---|---|---  
 | ∣|  = private [ | ] [constr-decl](typedecl.html#constr-decl) { | [constr-decl](typedecl.html#constr-decl) }   
 | ∣|  = private [record-decl](typedecl.html#record-decl)  
  
Values of a variant or record type declared private can be de-structured
normally in pattern-matching or via the [expr](expr.html#expr) .
[field](names.html#field) notation for record accesses. However, values of
these types cannot be constructed directly by constructor application or
record construction. Moreover, assignment on a mutable field of a private
record type is not allowed.

The typical use of private types is in the export signature of a module, to
ensure that construction of values of the private type always go through the
functions provided by the module, while still allowing pattern-matching
outside the defining module. For example:

module M : sig type t = private A | B of int val a : t val b : int -> t end = struct type t = A | B of int let a = A let b n = assert (n > 0); B n end

Here, the private declaration ensures that in any value of type M.t, the
argument to the B constructor is always a positive integer.

With respect to the variance of their parameters, private types are handled
like abstract types. That is, if a private type has parameters, their variance
is the one explicitly given by prefixing the parameter by a ‘+’ or a ‘-’, it
is invariant otherwise.

### ﻿12.3.2 Private type abbreviations

(Introduced in Objective Caml 3.11)

| [type-equation](typedecl.html#type-equation)| ::=|  ...  
---|---|---  
 | ∣|  = private [typexpr](types.html#typexpr)  
  
Unlike a regular type abbreviation, a private type abbreviation declares a
type that is distinct from its implementation type
[typexpr](types.html#typexpr). However, coercions from the type to
[typexpr](types.html#typexpr) are permitted. Moreover, the compiler “knows”
the implementation type and can take advantage of this knowledge to perform
type-directed optimizations.

The following example uses a private type abbreviation to define a module of
nonnegative integers:

module N : sig type t = private int val of_int: int -> t val to_int: t -> int
end = struct type t = int let of_int n = assert (n >= 0); n let to_int n = n
end

The type N.t is incompatible with int, ensuring that nonnegative integers and
regular integers are not confused. However, if x has type N.t, the coercion (x
:> int) is legal and returns the underlying integer, just like N.to_int x.
Deep coercions are also supported: if l has type N.t list, the coercion (l :>
int list) returns the list of underlying integers, like List.map N.to_int l
but without copying the list l.

Note that the coercion ( [expr](expr.html#expr) :>
[typexpr](types.html#typexpr) ) is actually an abbreviated form, and will only
work in presence of private abbreviations if neither the type of
[expr](expr.html#expr) nor [typexpr](types.html#typexpr) contain any type
variables. If they do, you must use the full form ( [expr](expr.html#expr) :
[typexpr](types.html#typexpr)1 :> [typexpr](types.html#typexpr)2 ) where
[typexpr](types.html#typexpr)1 is the expected type of [expr](expr.html#expr).
Concretely, this would be (x : N.t :> int) and (l : N.t list :> int list) for
the above examples.

### ﻿12.3.3 Private row types

(Introduced in Objective Caml 3.09)

| [type-equation](typedecl.html#type-equation)| ::=|  ...  
---|---|---  
 | ∣|  = private [typexpr](types.html#typexpr)  
  
Private row types are type abbreviations where part of the structure of the
type is left abstract. Concretely [typexpr](types.html#typexpr) in the above
should denote either an object type or a polymorphic variant type, with some
possibility of refinement left. If the private declaration is used in an
interface, the corresponding implementation may either provide a ground
instance, or a refined private type.

module M : sig type c = private < x : int; .. > val o : c end = struct class c
= object method x = 3 method y = 2 end let o = new c end

This declaration does more than hiding the y method, it also makes the type c
incompatible with any other closed object type, meaning that only o will be of
type c. In that respect it behaves similarly to private record types. But
private row types are more flexible with respect to incremental refinement.
This feature can be used in combination with functors.

module F(X : sig type c = private < x : int; .. > end) = struct let get_x (o :
X.c) = o#x end module G(X : sig type c = private < x : int; y : int; .. > end)
= struct include F(X) let get_y (o : X.c) = o#y end

A polymorphic variant type [t], for example

type t = [ `A of int | `B of bool ]

can be refined in two ways. A definition [u] may add new field to [t], and the
declaration

type u = private [> t]

will keep those new fields abstract. Construction of values of type [u] is
possible using the known variants of [t], but any pattern-matching will
require a default case to handle the potential extra fields. Dually, a
declaration [u] may restrict the fields of [t] through abstraction: the
declaration

type v = private [< t > `A]

corresponds to private variant types. One cannot create a value of the private
type [v], except using the constructors that are explicitly listed as present,
(`A n) in this example; yet, when pattern-matching on a [v], one should assume
that any of the constructors of [t] could be present.

Similarly to abstract types, the variance of type parameters is not inferred,
and must be given explicitly.

* * *

[![Previous](previous_motif.svg)](recursivemodules.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](locallyabstract.html)

