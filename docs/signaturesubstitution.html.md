[![Previous](previous_motif.svg)](moduletypeof.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](modulealias.html)

* * *

## ﻿12.7 Substituting inside a signature

  * [12.7.1 Destructive substitutions](signaturesubstitution.html#ss%3Adestructive-substitution)
  * [12.7.2 Local substitution declarations](signaturesubstitution.html#ss%3Alocal-substitution)
  * [12.7.3 Module type substitutions](signaturesubstitution.html#ss%3Amodule-type-substitution)

### ﻿12.7.1 Destructive substitutions

(Introduced in OCaml 3.12, generalized in 4.06)

| [mod-constraint](modtypes.html#mod-constraint)| ::=|  ...  
---|---|---  
 | ∣|  type [[type-params](typedecl.html#type-params)] [typeconstr-name](names.html#typeconstr-name) := [typexpr](types.html#typexpr)  
 | ∣|  module [module-path](names.html#module-path) := [extended-module-path](names.html#extended-module-path)  
  
A “destructive” substitution (with ... := ...) behaves essentially like normal
signature constraints (with ... = ...), but it additionally removes the
redefined type or module from the signature.

Prior to OCaml 4.06, there were a number of restrictions: one could only
remove types and modules at the outermost level (not inside submodules), and
in the case of with type the definition had to be another type constructor
with the same type parameters.

A natural application of destructive substitution is merging two signatures
sharing a type name.

module type Printable = sig type t val print : Format.formatter -> t -> unit
end module type Comparable = sig type t val compare : t -> t -> int end module
type PrintableComparable = sig include Printable include Comparable with type
t := t end

One can also use this to completely remove a field:

module type S = Comparable with type t := int

module type S = sig val compare : int -> int -> int end

or to rename one:

module type S = sig type u include Comparable with type t := u end

module type S = sig type u val compare : u -> u -> int end

Note that you can also remove manifest types, by substituting with the same
type.

module type ComparableInt = Comparable with type t = int ;;

module type ComparableInt = sig type t = int val compare : t -> t -> int end

module type CompareInt = ComparableInt with type t := int

module type CompareInt = sig val compare : int -> int -> int end

### ﻿12.7.2 Local substitution declarations

(Introduced in OCaml 4.08, module type substitution introduced in 4.13)

| [specification](modtypes.html#specification)| ::=|  ...  
---|---|---  
 | ∣|  type type-subst { and type-subst }   
 | ∣|  module [module-name](names.html#module-name) := [extended-module-path](names.html#extended-module-path)  
 | ∣|  module type [module-name](names.html#module-name) := [module-type](modtypes.html#module-type)  
  
type-subst| ::=|  [[type-params](typedecl.html#type-params)] [typeconstr-
name](names.html#typeconstr-name) := [typexpr](types.html#typexpr) { [type-
constraint](typedecl.html#type-constraint) }  
  
Local substitutions behave like destructive substitutions (with ... := ...)
but instead of being applied to a whole signature after the fact, they are
introduced during the specification of the signature, and will apply to all
the items that follow.

This provides a convenient way to introduce local names for types and modules
when defining a signature:

module type S = sig type t module Sub : sig type outer := t type t val
to_outer : t -> outer end end

module type S = sig type t module Sub : sig type t val to_outer : t -> t/2 end
end

Note that, unlike type declarations, type substitution declarations are not
recursive, so substitutions like the following are rejected:

# module type S = sig type 'a poly_list := [ `Cons of 'a * 'a poly_list | `Nil ] end ;;

Error: Unbound type constructor poly_list

Local substitutions can also be used to give a local name to a type or a
module type introduced by a functor application:

# module type F = sig type set := Set.Make(Int).t module type Type = sig type
t end module Nest : Type -> sig module type T = Type end module type T :=
Nest(Int).T val set: set val m : (module T) end;;

module type F = sig module type Type = sig type t end module Nest : Type ->
sig module type T = Type end val set : Set.Make(Int).t val m : (module
Nest(Int).T) end

Local module type substitutions are subject to the same limitations as module
type substitutions, see section 12.7.3.

### ﻿12.7.3 Module type substitutions

(Introduced in OCaml 4.13)

| [mod-constraint](modtypes.html#mod-constraint)| ::=|  ...  
---|---|---  
 | ∣|  module type [modtype-path](names.html#modtype-path) = [module-type](modtypes.html#module-type)  
 | ∣|  module type [modtype-path](names.html#modtype-path) := [module-type](modtypes.html#module-type)  
  
Module type substitution essentially behaves like type substitutions. They are
useful to refine an abstract module type in a signature into a concrete module
type,

# module type ENDO = sig module type T module F: T -> T end module Endo(X: sig
module type T end): ENDO with module type T = X.T = struct module type T = X.T
module F(X:T) = X end;;

module type ENDO = sig module type T module F : T -> T end module Endo : (X :
sig module type T end) -> sig module type T = X.T module F : T -> T end

It is also possible to substitute a concrete module type with an equivalent
module types.

module type A = sig type x module type R = sig type a = A of x type b end end
module type S = sig type a = A of int type b end module type B = A with type x
= int and module type R = S

However, such substitutions are never necessary.

Destructive module type substitution removes the module type substitution from
the signature

# module type ENDO' = ENDO with module type T := ENDO;;

module type ENDO' = sig module F : ENDO -> ENDO end

#### ﻿Limitations

If the right hand side of a module type substitution or a local module type
substitution is not a [modtype-path](names.html#modtype-path), then the
destructive substitution is only valid if the left-hand side of the
substitution is never used as the type of a first-class module in the original
module type.

module type T = sig module type S val x: (module S) end module type Error = T
with module type S := sig end

Error: This with constraint S := sig end makes a packed module ill-formed.
(see manual section 12.7.3)

module type T = sig module type S := sig end val x: (module S) end

Error: The module type S is not a valid type for a packed module: it is
defined as a local substitution (temporary name) for an anonymous module type.
(see manual section 12.7.3)

* * *

[![Previous](previous_motif.svg)](moduletypeof.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](modulealias.html)

