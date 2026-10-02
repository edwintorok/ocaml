[![Previous](previous_motif.svg)](letrecvalues.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](privatetypes.html)

* * *

## ﻿12.2 Recursive modules

(Introduced in Objective Caml 3.07)

| [definition](modules.html#definition)| ::=|  ...  
---|---|---  
 | ∣|  module rec [module-name](names.html#module-name) : [module-type](modtypes.html#module-type) = [module-expr](modules.html#module-expr) { and [module-name](names.html#module-name) : [module-type](modtypes.html#module-type) = [module-expr](modules.html#module-expr) }   
  
[specification](modtypes.html#specification)| ::=|  ...  
 | ∣|  module rec [module-name](names.html#module-name) : [module-type](modtypes.html#module-type) { and [module-name](names.html#module-name): [module-type](modtypes.html#module-type) }   
  
Recursive module definitions, introduced by the module rec …and …
construction, generalize regular module definitions module [module-
name](names.html#module-name) = [module-expr](modules.html#module-expr) and
module specifications module [module-name](names.html#module-name) : [module-
type](modtypes.html#module-type) by allowing the defining [module-
expr](modules.html#module-expr) and the [module-type](modtypes.html#module-
type) to refer recursively to the module identifiers being defined. A typical
example of a recursive module definition is:

module rec A : sig type t = Leaf of string | Node of ASet.t val compare: t -> t -> int end = struct type t = Leaf of string | Node of ASet.t let compare t1 t2 = match (t1, t2) with | (Leaf s1, Leaf s2) -> Stdlib.compare s1 s2 | (Leaf _, Node _) -> 1 | (Node _, Leaf _) -> -1 | (Node n1, Node n2) -> ASet.compare n1 n2 end and ASet : Set.S with type elt = A.t = Set.Make(A)

It can be given the following specification:

module rec A : sig type t = Leaf of string | Node of ASet.t val compare: t -> t -> int end and ASet : Set.S with type elt = A.t

This is an experimental extension of OCaml: the class of recursive definitions
accepted, as well as its dynamic semantics are not final and subject to change
in future releases.

Currently, the compiler requires that all dependency cycles between the
recursively-defined module identifiers go through at least one “safe” module.
A module is “safe” if all value definitions that it contains have function
types [typexpr](types.html#typexpr)1 -> [typexpr](types.html#typexpr)2.
Evaluation of a recursive module definition proceeds by building initial
values for the safe modules involved, binding all (functional) values to fun _
-> raise Undefined_recursive_module. The defining module expressions are then
evaluated, and the initial values for the safe modules are replaced by the
values thus computed. If a function component of a safe module is applied
during this computation (which corresponds to an ill-founded recursive
definition), the Undefined_recursive_module exception is raised at runtime:

module rec M: sig val f: unit -> int end = struct let f () = N.x end and N:sig
val x: int end = struct let x = M.f () end

Exception: Undefined_recursive_module ("extensions/recursivemodules.etex", 1,
43).

If there are no safe modules along a dependency cycle, an error is raised

module rec M: sig val x: int end = struct let x = N.y end and N:sig val x: int
val y:int end = struct let x = M.x let y = 0 end

Error: Cannot safely evaluate the definition of the following cycle of
recursively-defined modules: M -> N -> M. There are no safe modules in this
cycle (see manual section 12.2). Module M defines an unsafe value, x . Module
N defines an unsafe value, x .

Note that, in the [specification](modtypes.html#specification) case, the
[module-type](modtypes.html#module-type)s must be parenthesized if they use
the with [mod-constraint](modtypes.html#mod-constraint) construct.

* * *

[![Previous](previous_motif.svg)](letrecvalues.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](privatetypes.html)

