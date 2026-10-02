[![Previous](previous_motif.svg)](alerts.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](bindingops.html)

* * *

## ﻿12.22 Generalized open statements

(Introduced in 4.08)

| [definition](modules.html#definition)| ::=|  ...  
---|---|---  
 | ∣|  open [module-expr](modules.html#module-expr)  
 | ∣|  open! [module-expr](modules.html#module-expr)  
  
[specification](modtypes.html#specification)| ::=|  ...  
 | ∣|  open [extended-module-path](names.html#extended-module-path)  
 | ∣|  open! [extended-module-path](names.html#extended-module-path)  
  
[expr](expr.html#expr)| ::=|  ...  
 | ∣|  let open [module-expr](modules.html#module-expr) in [expr](expr.html#expr)  
 | ∣|  let open! [module-expr](modules.html#module-expr) in [expr](expr.html#expr)  
  
  
This extension makes it possible to open any module expression in module
structures and expressions. A similar mechanism is also available inside
module types, but only for extended module paths (e.g. F(X).G(Y)).

For instance, a module can be constrained when opened with

module M = struct let x = 0 let hidden = 1 end open (M:sig val x: int end) let
y = hidden

Error: Unbound value hidden

Another possibility is to immediately open the result of a functor application

let sort (type x) (x:x list) = let open Set.Make(struct type t = x let
compare=compare end) in elements (of_list x)

val sort : 'x list -> 'x list = <fun>

Going further, this construction can introduce local components inside a
structure,

module M = struct let x = 0 open! struct let x = 0 let y = 1 end let w = x + y
end

module M : sig val x : int val w : int end

One important restriction is that types introduced by open struct ... end
cannot appear in the signature of the enclosing structure, unless they are
defined equal to some non-local type. So:

module M = struct open struct type 'a t = 'a option = None | Some of 'a end let x : int t = Some 1 end

module M : sig val x : int option end

is OK, but:

module M = struct open struct type t = A end let x = A end

Error: The type t introduced by this open appears in the signature. The value
x has no valid type if t is hidden.

is not because x cannot be given any type other than t, which only exists
locally. Although the above would be OK if x too was local:

module M: sig end = struct open struct type t = A end … open struct let x = A
end … end

module M : sig end

Inside signatures, extended opens are limited to extended module paths,

module type S = sig module F: sig end -> sig type t end module X: sig end open
F(X) val f: t end

module type S = sig module F : sig end -> sig type t end module X : sig end
val f : F(X).t end

and not

    
    
      open struct type t = int end
    

In those situations, local substitutions(see
[12.7.2](signaturesubstitution.html#ss%3Alocal-substitution)) can be used
instead.

Beware that this extension is not available inside class definitions:

    
    
    class c =
      let open Set.Make(Int) in
      ...
    

* * *

[![Previous](previous_motif.svg)](alerts.html)
[![Up](contents_motif.svg)](extn.html)
[![Next](next_motif.svg)](bindingops.html)

